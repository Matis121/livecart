module Integrations
  module Baselinker
    class OrderStatusImporter < Integrations::BaseImporter
      # Baselinker journal log_type for order status changes
      STATUS_CHANGE_LOG_TYPE = 6

      def call
        track_stats do |stats|
          client = Client.new(integration)
          last_log_id = integration.last_journal_log_id
          # Baselinker requires last_log_id > 0; use 1 on first run to get last 3 days of events
          last_log_id = 1 if last_log_id.zero?

          log_info("Fetching Baselinker journal since log_id=#{last_log_id}...")

          journal_response = client.get_journal_list(last_log_id)
          logs = journal_response.dig("logs") || []

          log_info("Journal response keys: #{journal_response.keys.inspect}, logs count: #{logs.size}")

          if logs.empty? && last_log_id == 1
            log_info("Journal empty on first run - Journal API may be disabled in Baselinker. Falling back to getOrders with date filter...")
            sync_via_recent_orders(client, stats)
            integration.mark_sync_success!
            next Result.success(message: "Synced via recent orders fallback", updated_count: stats[:updated_count], failed_count: stats[:failed_count])
          elsif logs.empty?
            log_info("No new journal events")
            integration.mark_sync_success!
            next Result.success(message: "No new events", updated_count: 0, failed_count: 0)
          end

          log_info("Found #{logs.size} journal events")

          # Filter status-change events and collect unique Baselinker order IDs
          changed_order_ids = logs
            .select { |entry| entry["log_type"].to_i == STATUS_CHANGE_LOG_TYPE }
            .map { |entry| entry["order_id"].to_i }
            .uniq

          log_info("#{changed_order_ids.size} orders had status changes")

          # Build a lookup: baselinker_order_id → LiveCart order
          export_records = IntegrationExport
            .where(integration: integration, external_id: changed_order_ids.map(&:to_s), status: :success)
            .includes(:order)
          order_by_bl_id = export_records.each_with_object({}) do |rec, h|
            h[rec.external_id.to_i] = rec.order
          end

          changed_order_ids.each do |bl_order_id|
            order = order_by_bl_id[bl_order_id]
            unless order
              log_info("Baselinker order #{bl_order_id} not found in LiveCart exports - skipping")
              next
            end
            sync_order_status(order, bl_order_id, client, stats)
          end

          # Persist the highest log_id so next run only fetches new events
          max_log_id = logs.map { |e| e["log_id"].to_i }.max
          integration.update_last_journal_log_id!(max_log_id)
          integration.mark_sync_success!

          Result.success(
            message: "Order status import completed",
            updated_count: stats[:updated_count],
            failed_count: stats[:failed_count]
          )
        end
      rescue Integrations::IntegrationError => e
        integration.mark_sync_error!(e.message)
        Result.failure(errors: [ e.message ])
      end

      private

      def sync_order_status(order, bl_order_id, client, stats)
        response = client.get_order(bl_order_id)
        baselinker_order = response.dig("order")

        unless baselinker_order
          log_info("Order not found in Baselinker (ID: #{bl_order_id}) - skipping")
          return
        end

        baselinker_status_id = baselinker_order.dig("order_status_id").to_i
        log_info("Order #{order.order_number} - Baselinker status_id: #{baselinker_status_id}")

        new_status = map_baselinker_status_to_order_status(baselinker_status_id)

        unless new_status
          log_info("No mapping for Baselinker status #{baselinker_status_id} - skipping")
          return
        end

        if order.status.to_s != new_status.to_s
          old_status = order.status
          order.update!(status: new_status)
          log_success("Order #{order.order_number}: #{old_status} → #{new_status}")
          stats[:updated_count] += 1
        else
          log_info("Order #{order.order_number} already #{new_status}")
        end
      rescue StandardError => e
        log_error("Error syncing order #{order.order_number}: #{e.message}")
        stats[:failed_count] += 1
        stats[:errors] << "Order #{order.order_number}: #{e.message}"
      end

      # Fallback when Journal API is disabled.
      # Fetches orders confirmed in the last 48h from Baselinker (1 API call, up to 100 orders)
      # and updates statuses for orders we have in LiveCart exports.
      def sync_via_recent_orders(client, stats)
        date_from = 48.hours.ago.to_i
        page_date_from = date_from

        loop do
          response = client.get_orders(date_confirmed_from: page_date_from, get_unconfirmed_orders: false)
          bl_orders = response.dig("orders") || {}
          bl_orders = bl_orders.values if bl_orders.is_a?(Hash)

          break if bl_orders.empty?

          log_info("Fallback: checking #{bl_orders.size} recent Baselinker orders")

          bl_order_ids = bl_orders.map { |o| o["order_id"].to_s }
          export_records = IntegrationExport
            .where(integration: integration, external_id: bl_order_ids, status: :success)
            .includes(:order)
            .index_by(&:external_id)

          bl_orders.each do |bl_order|
            rec = export_records[bl_order["order_id"].to_s]
            next unless rec

            order = rec.order
            bl_status_id = bl_order["order_status_id"].to_i
            new_status = map_baselinker_status_to_order_status(bl_status_id)
            next unless new_status

            if order.status.to_s != new_status.to_s
              old_status = order.status
              order.update!(status: new_status)
              log_success("Order #{order.order_number}: #{old_status} → #{new_status}")
              stats[:updated_count] += 1
            end
          rescue StandardError => e
            log_error("Error on order #{rec&.order&.order_number}: #{e.message}")
            stats[:failed_count] += 1
          end

          # Baselinker returns max 100 orders; paginate using last date_confirmed
          break if bl_orders.size < 100

          page_date_from = bl_orders.last["date_confirmed"].to_i
        end
      end

      # Settings store { "livecart_status" => "baselinker_id" }, invert for lookup
      def map_baselinker_status_to_order_status(baselinker_status_id)
        raw_mapping = integration.status_mapping || {}

        inverted = raw_mapping.each_with_object({}) do |(livecart_status, bl_id), h|
          h[bl_id.to_s] = livecart_status if bl_id.present?
        end

        mapped = inverted[baselinker_status_id.to_s]
        return nil unless mapped

        mapped.to_sym if Order.statuses.key?(mapped.to_s)
      end
    end
  end
end
