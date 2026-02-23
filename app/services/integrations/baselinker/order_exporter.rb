module Integrations
  module Baselinker
    class OrderExporter < Integrations::BaseExporter
      def call(order)
        log_info("Exporting order #{order.order_number} to Baselinker...")

        # Create or find export record for idempotency tracking
        export_record = order.integration_exports.find_or_create_by!(integration: integration) do |record|
          record.status = :pending
        end

        # Skip if already successfully exported
        if export_record.status_success?
          log_info("Order already exported (external_id: #{export_record.external_id}) - skipping")
          return Result.success(
            data: { baselinker_order_id: export_record.external_id },
            message: "Order already exported"
          )
        end

        # Mark as pending if it was failed before (retry)
        export_record.update!(status: :pending) if export_record.status_failed?

        client = Client.new(integration)
        order_data = prepare_order_data(order)

        response = client.add_order(order_data)
        order_id = response.dig("order_id")

        if order_id
          log_success("Order #{order.order_number} exported to Baselinker (ID: #{order_id})")

          # Mark export as successful
          export_record.mark_success!(order_id.to_s)

          Result.success(
            data: { baselinker_order_id: order_id },
            message: "Order exported successfully"
          )
        else
          error_message = "No order_id returned from Baselinker"
          log_error(error_message)
          export_record.mark_failed!(error_message)
          Result.failure(errors: [ error_message ])
        end
      rescue Integrations::IntegrationError => e
        log_error("Failed to export order: #{e.message}")
        export_record&.mark_failed!(e.message)
        Result.failure(errors: [ e.message ])
      rescue StandardError => e
        log_error("Unexpected error: #{e.message}")
        export_record&.mark_failed!(e.message)
        Result.failure(errors: [ e.message ])
      end

      private

      def prepare_order_data(order)
        {
          # Order basic info
          order_status_id: baselinker_status_from_order(order),
          custom_source_id: integration.settings.dig("custom_source_id"),

          # Customer info
          email: order.email,
          phone: order.phone,

          # Delivery address
          delivery_fullname: delivery_fullname(order),
          delivery_address: order.shipping_address&.address_line1,
          delivery_city: order.shipping_address&.city,
          delivery_postcode: order.shipping_address&.postal_code,
          delivery_country_code: order.shipping_address&.country || "PL",

          # Invoice address (if different)
          invoice_fullname: invoice_fullname(order),
          invoice_company: order.billing_address&.company_name,
          invoice_nip: order.billing_address&.nip,
          invoice_address: order.billing_address&.address_line1,
          invoice_city: order.billing_address&.city,
          invoice_postcode: order.billing_address&.postal_code,
          invoice_country_code: order.billing_address&.country || "PL",

          # Products
          products: prepare_products(order),

          # Payment and shipping
          payment_method: order.payment_method,
          delivery_method: order.shipping_method,
          delivery_price: order.shipping_cost.to_f,

          # Currency
          currency: order.currency,

          # Custom fields
          user_comments: "Zamówienie z LiveCart ##{order.order_number}",
          admin_comments: "Zaimportowane z LiveCart"
        }.compact
      end

      def prepare_products(order)
        order.order_items.map do |item|
          product_data = {
            name: item.name,
            sku: item.sku || "",
            ean: item.ean || "",
            price_brutto: item.unit_price.to_f,
            quantity: item.quantity,
            tax_rate: item.product&.tax_rate || 23
          }

          if item.product&.baselinker_linked?
            product_data[:storage_id] = @integration.inventory_id
            product_data[:product_id] = item.product.baselinker_product_id
          end

          product_data
        end
      end

      def delivery_fullname(order)
        return nil unless order.shipping_address

        "#{order.shipping_address.first_name} #{order.shipping_address.last_name}".strip
      end

      def invoice_fullname(order)
        return nil unless order.billing_address

        "#{order.billing_address.first_name} #{order.billing_address.last_name}".strip
      end

      def baselinker_status_from_order(order)
        status_id = integration.baselinker_status_id

        if status_id.present?
          status_id.to_i
        else
          raise Integrations::IntegrationError,
                "Baselinker status ID not configured. Please set 'ID statusu w Baselinker' in integration settings."
        end
      end
    end
  end
end
