module Integrations
  module Baselinker
    # Import stock quantities from Baselinker to LiveCart
    # Matches products by SKU or EAN, updates ProductStock
    class StockImporter < Integrations::BaseImporter
      def call
        track_stats do |stats|
          log_info("Starting stock import from Baselinker...")

          inventory_id = integration.inventory_id
          if inventory_id.blank?
            return Result.failure(errors: [ "Inventory ID not configured. Please set 'ID katalogu produktów' in integration settings." ])
          end

          client = Client.new(integration)
          products_data = client.get_products_from_inventory(inventory_id.to_i)

          log_info("Found #{products_data.count} products in Baselinker inventory #{inventory_id}")

          products_data.each do |product_data|
            process_product_stock(product_data, stats)
          end

          integration.mark_sync_success!

          Result.success(
            message: "Stock import completed",
            updated_count: stats[:updated_count],
            failed_count: stats[:failed_count]
          )
        end
      rescue Integrations::IntegrationError => e
        integration.mark_sync_error!(e.message)
        Result.failure(errors: [ e.message ])
      end

      private

      def process_product_stock(product_data, stats)
        sku = product_data.dig("sku")
        ean = product_data.dig("ean")
        name = product_data.dig("name")

        # Baselinker returns stock as Hash with warehouse_id as keys
        # Example: {"bl_36537" => 44} where value is directly the stock quantity
        stock_data = product_data.dig("stock") || {}

        # Sum stock from all warehouses
        stock_quantity = 0
        stock_data.each do |warehouse_id, warehouse_info|
          if warehouse_info.is_a?(Hash)
            # If it's a hash, try to get stock from various keys
            warehouse_stock = warehouse_info["bl_stock"]&.to_i || warehouse_info["stock"]&.to_i || 0
          else
            # If it's a direct number, use it
            warehouse_stock = warehouse_info.to_i
          end
          stock_quantity += warehouse_stock
        end

        log_info("Product #{sku} (#{name}) - stock data: #{stock_data.inspect}, total: #{stock_quantity}")

        return if sku.blank? && ean.blank? && name.blank?

        # Find matching product in LiveCart using configured match method
        match_by = integration.stock_match_by
        product = Products::Matcher.call(
          account: account,
          sku: sku,
          ean: ean,
          name: name,
          match_by: match_by
        )

        unless product
          log_info("Product not found (SKU: #{sku}, EAN: #{ean}, Name: #{name}) - skipping")
          stats[:failed_count] += 1
          stats[:errors] << "Product not found: SKU=#{sku}, EAN=#{ean}, Name=#{name}"
          return
        end

        # Update stock using Stock Updater service
        result = Products::StockUpdater.call(
          product: product,
          new_quantity: stock_quantity,
          source: :baselinker_import
        )

        if result.success?
          log_success("Updated stock for #{product.name}: #{stock_quantity}")
          stats[:updated_count] += 1
        else
          log_error("Failed to update stock for #{product.name}: #{result.errors.join(', ')}")
          stats[:failed_count] += 1
          stats[:errors] << "#{product.name}: #{result.errors.join(', ')}"
        end
      rescue StandardError => e
        log_error("Error processing product (SKU: #{sku}): #{e.message}")
        stats[:failed_count] += 1
        stats[:errors] << "SKU #{sku}: #{e.message}"
      end
    end
  end
end
