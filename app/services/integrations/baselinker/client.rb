module Integrations
  module Baselinker
    # Baselinker API Client
    # Documentation: https://api.baselinker.com/
    class Client < Integrations::BaseClient
      BASE_URL = "https://api.baselinker.com/connector.php"

      def initialize(integration)
        super(base_url: BASE_URL, integration: integration, timeout: 60)
        # Override connection to not use JSON middleware (Baselinker uses form encoding)
        @connection = build_baselinker_connection
      end

      private

      def build_baselinker_connection
        Faraday.new(url: BASE_URL) do |conn|
          # Request middleware - URL encoded for Baselinker
          conn.request :url_encoded
          conn.request :retry,
            max: 3,
            interval: 0.5,
            interval_randomness: 0.5,
            backoff_factor: 2,
            exceptions: [
              Faraday::TimeoutError,
              Faraday::ConnectionFailed,
              Errno::ETIMEDOUT
            ]

          # Response middleware
          conn.response :json, content_type: /\bjson$/
          conn.response :raise_error

          # Adapter
          conn.adapter Faraday.default_adapter

          # Timeouts
          conn.options.timeout = 60
          conn.options.open_timeout = 10
        end
      end

      public

      # Get inventory list
      def get_inventories
        call_method("getInventories")
      end

      # Get products from inventory
      # @param inventory_id [Integer] Baselinker inventory ID
      def get_inventory_products(inventory_id)
        call_method("getInventoryProductsList", {
          inventory_id: inventory_id
        })
      end

      # Get product stock and prices
      # @param inventory_id [Integer] Baselinker inventory ID
      # @param product_ids [Array<Integer>] Product IDs
      def get_inventory_products_data(inventory_id, product_ids)
        call_method("getInventoryProductsData", {
          inventory_id: inventory_id,
          products: product_ids
        })
      end

      # Get all products with stock from all inventories
      def get_all_products_with_stock
        inventories = get_inventories
        all_products = []

        inventories.dig("inventories")&.each do |inventory|
          inventory_id = inventory["inventory_id"]

          # Get product list
          products_list = get_inventory_products(inventory_id)
          product_ids = products_list.dig("products")&.keys || []

          next if product_ids.empty?

          # Get detailed product data in batches (Baselinker limit is 1000 per request)
          product_ids.each_slice(100) do |batch_ids|
            products_data = get_inventory_products_data(inventory_id, batch_ids)
            # Baselinker returns products as Hash with product_id as keys
            # Convert to array of product hashes
            products_hash = products_data.dig("products") || {}
            products = products_hash.values
            all_products.concat(products)
          end
        end

        all_products
      end

      # Get products with stock from specific inventory
      # @param inventory_id [Integer] Baselinker inventory ID
      def get_products_from_inventory(inventory_id)
        return [] if inventory_id.blank?

        all_products = []

        # Get product list
        products_list = get_inventory_products(inventory_id)
        product_ids = products_list.dig("products")&.keys || []

        return [] if product_ids.empty?

        # Get detailed product data in batches (Baselinker limit is 1000 per request)
        product_ids.each_slice(100) do |batch_ids|
          products_data = get_inventory_products_data(inventory_id, batch_ids)
          # Baselinker returns products as Hash with product_id as keys
          # Convert to array of product hashes
          products_hash = products_data.dig("products") || {}
          products = products_hash.values
          all_products.concat(products)
        end

        all_products
      end

      # Add order to Baselinker
      # @param order_data [Hash] Order data formatted for Baselinker
      def add_order(order_data)
        call_method("addOrder", order_data)
      end

      # Get a single order details from Baselinker
      # @param order_id [Integer] Baselinker order ID
      def get_order(order_id)
        response = call_method("getOrders", { order_id: order_id })
        # Baselinker returns orders as a Hash keyed by order_id
        orders = response.dig("orders") || {}
        order = orders.is_a?(Hash) ? orders.values.first : orders.first
        { "order" => order }
      end

      # Get order events journal (changes, status updates, etc.)
      # @param last_log_id [Integer] Only return events with ID > last_log_id (0 = last 3 days)
      def get_journal_list(last_log_id = 0)
        call_method("getJournalList", { last_log_id: last_log_id })
      end

      # Get orders list from Baselinker
      # @param filters [Hash] Optional filters (date_confirmed_from, order_id, etc.)
      def get_orders(filters = {})
        call_method("getOrders", filters)
      end

      # Update order status
      def update_order_status(order_id, status_id)
        call_method("setOrderStatus", {
          order_id: order_id,
          status_id: status_id
        })
      end

      private

      # Baselinker uses POST with method parameter
      def call_method(method_name, parameters = {})
        payload = {
          method: method_name,
          parameters: parameters.to_json
        }

        response = post("", payload)

        # Baselinker returns {status: "SUCCESS|ERROR", ...}
        if response["status"] == "ERROR"
          error_message = response["error_message"] || "Unknown error"
          raise Integrations::IntegrationError, "Baselinker API error: #{error_message}"
        end

        response
      end

      def default_headers
        super.merge(auth_headers)
      end

      def auth_headers
        {
          "X-BLToken" => integration.api_key
        }
      end

      # Override to handle Baselinker response format
      def post(path, body = {}, headers = {})
        with_error_handling do
          log_request(:post, "connector.php", body)

          # Baselinker expects form-encoded data with 'method' and 'parameters' fields
          response = connection.post do |req|
            req.headers.update(default_headers)
            req.headers.update(headers)
            req.body = body
          end

          log_response(response)
          response.body
        end
      end
    end
  end
end
