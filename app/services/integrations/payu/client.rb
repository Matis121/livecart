module Integrations
  module Payu
    class Client < Integrations::BaseClient
      PRODUCTION_BASE_URL = "https://secure.payu.com"
      SANDBOX_BASE_URL    = "https://secure.snd.payu.com"

      def initialize(integration)
        base_url = integration.payu_sandbox? ? SANDBOX_BASE_URL : PRODUCTION_BASE_URL
        super(base_url: base_url, integration: integration, timeout: 30)
      end

      # Returns { payu_order_id: String, redirect_uri: String }
      def create_order(order, notify_url:, continue_url:, customer_ip:)
        token = fetch_access_token
        payload = build_order_payload(order, notify_url: notify_url, continue_url: continue_url, customer_ip: customer_ip)

        # Call directly on connection to access response headers (PayU returns 302)
        response = connection.post("/api/v2_1/orders", payload,
          default_headers.merge(
            "Authorization" => "Bearer #{token}",
            "Content-Type" => "application/json"
          )
        )

        body = response.body
        # PayU returns 302: redirect_uri is in Location header; body has orderId
        redirect_uri = response.headers["location"] || body["redirectUri"]

        status_code = body.dig("status", "statusCode")
        unless status_code == "SUCCESS"
          raise IntegrationError, "PayU error: #{body.dig('status', 'statusDesc') || status_code}"
        end

        raise IntegrationError, "PayU returned no redirect URI" if redirect_uri.blank?

        {
          payu_order_id: body["orderId"],
          redirect_uri: redirect_uri
        }
      rescue Faraday::Error => e
        raise IntegrationError, "PayU request failed: #{e.message}"
      end

      private

      def fetch_access_token
        base_url = integration.payu_sandbox? ? SANDBOX_BASE_URL : PRODUCTION_BASE_URL

        auth_connection = Faraday.new(url: base_url) do |conn|
          conn.request :url_encoded
          conn.response :json, content_type: /\bjson$/
          conn.response :raise_error
          conn.options.timeout = 15
          conn.options.open_timeout = 10
          conn.adapter Faraday.default_adapter
        end

        response = auth_connection.post("/pl/standard/user/oauth/authorize",
          grant_type: "client_credentials",
          client_id: integration.api_key,
          client_secret: integration.api_secret
        )

        token = response.body["access_token"]
        raise IntegrationError, "Failed to obtain PayU access token" if token.blank?

        token
      rescue Faraday::Error => e
        raise IntegrationError, "PayU OAuth failed: #{e.message}"
      end

      def build_order_payload(order, notify_url:, continue_url:, customer_ip:)
        addr = order.shipping_address

        {
          merchantPosId: integration.api_key,
          notifyUrl: notify_url,
          customerIp: customer_ip,
          continueUrl: continue_url,
          currencyCode: order.currency,
          totalAmount: (order.total_amount * 100).to_i.to_s,
          description: "Zamówienie ##{order.order_number}",
          extOrderId: order.order_number,
          buyer: {
            email: order.email,
            phone: order.phone,
            firstName: addr&.first_name,
            lastName: addr&.last_name,
            language: "pl"
          },
          products: build_products(order)
        }
      end

      def build_products(order)
        items = order.order_items.map do |item|
          {
            name: item.name,
            unitPrice: (item.unit_price * 100).to_i.to_s,
            quantity: item.quantity.to_s
          }
        end

        if order.shipping_cost&.positive?
          items << {
            name: "Dostawa: #{order.shipping_method}",
            unitPrice: (order.shipping_cost * 100).to_i.to_s,
            quantity: "1"
          }
        end

        items
      end
    end
  end
end
