module Integrations
  module Payu
    class OrderCreator
      def initialize(integration:, order:)
        @integration = integration
        @order = order
      end

      # @param notify_url [String]
      # @param continue_url [String]
      # @param customer_ip [String]
      # @return [Integrations::Result]
      def call(notify_url:, continue_url:, customer_ip:)
        client = Client.new(@integration)
        result = client.create_order(
          @order,
          notify_url: notify_url,
          continue_url: continue_url,
          customer_ip: customer_ip
        )

        @order.update_column(:payu_order_id, result[:payu_order_id])

        Integrations::Result.success(
          data: { redirect_uri: result[:redirect_uri] },
          message: "PayU order created: #{result[:payu_order_id]}"
        )
      rescue Integrations::IntegrationError => e
        Rails.logger.error("[PAYU] OrderCreator failed for order #{@order.order_number}: #{e.message}")
        Integrations::Result.failure(errors: [ e.message ])
      rescue StandardError => e
        Rails.logger.error("[PAYU] Unexpected error for order #{@order.order_number}: #{e.class} - #{e.message}")
        Integrations::Result.failure(errors: [ "Nieoczekiwany błąd: #{e.message}" ])
      end
    end
  end
end
