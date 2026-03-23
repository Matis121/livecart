module Integrations
  class LiveDmSender
    attr_reader :transmission

    def initialize(transmission)
      @transmission = transmission
    end

    def call
      integration = transmission.integration
      return unless integration&.social_media_live?

      # Group transmission items by customer (only platform customers)
      platform_customers = transmission.transmission_items
        .includes(:customer, :product)
        .select { |ti| ti.customer&.platform == integration.provider && ti.customer.platform_user_id.present? }
        .group_by(&:customer)

      return if platform_customers.empty?

      poller_class = "Integrations::#{integration.provider.capitalize}::LiveChatPoller".constantize
      poller       = poller_class.new(integration)

      results = {}
      platform_customers.each do |customer, items|
        message = build_message(customer, items)
        begin
          poller.send_dm(customer.platform_user_id, message)
          results[customer.id] = { status: "sent" }
        rescue Integrations::IntegrationError => e
          if e.message.include?("403") || e.message.include?("insufficient_scope")
            results[customer.id] = { status: "fallback", message: message }
          else
            results[customer.id] = { status: "error", error: e.message, message: message }
          end
        end
      end

      integration.update_dm_result!(transmission.id, {
        "sent_at" => Time.current.iso8601,
        "results" => results,
        "status"  => results.values.all? { |r| r["status"] == "sent" } ? "sent" : "fallback"
      })
    end

    private

    def build_message(customer, items)
      lines = items.map do |ti|
        name = ti.product&.name || ti.name
        "• #{name} x#{ti.quantity} — #{format_price(ti.unit_price * ti.quantity)}"
      end

      total = items.sum { |ti| ti.unit_price * ti.quantity }

      <<~MSG.strip
        Dzień dobry @#{customer.platform_username}!
        Twoje zamówienie z transmisji live:
        #{lines.join("\n")}
        Suma: #{format_price(total)}
        Dziękujemy za zakup!
      MSG
    end

    def format_price(amount)
      "#{format("%.2f", amount)} zł"
    end
  end
end
