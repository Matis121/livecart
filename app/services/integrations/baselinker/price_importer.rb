module Integrations
  module Baselinker
    # Import product prices from Baselinker to LiveCart
    # Matches products by SKU or EAN, updates Product.gross_price
    class PriceImporter < Integrations::BaseImporter
      def call
        track_stats do |stats|
          log_info("Starting price import from Baselinker...")

          inventory_id = integration.inventory_id
          if inventory_id.blank?
            return Result.failure(errors: [ "Inventory ID not configured. Please set 'ID katalogu produktów' in integration settings." ])
          end

          client = Client.new(integration)
          products_data = client.get_products_from_inventory(inventory_id.to_i)

          log_info("Found #{products_data.count} products in Baselinker inventory #{inventory_id}")

          products_data.each do |product_data|
            process_product_price(product_data, stats)
          end

          integration.mark_sync_success!

          Result.success(
            message: "Price import completed",
            updated_count: stats[:updated_count],
            failed_count: stats[:failed_count]
          )
        end
      rescue Integrations::IntegrationError => e
        integration.mark_sync_error!(e.message)
        Result.failure(errors: [ e.message ])
      end

      private

      def process_product_price(product_data, stats)
        sku = product_data.dig("sku")
        ean = product_data.dig("ean")
        name = product_data.dig("name")

        # Baselinker prices can be in different price groups (0 = default)
        # prices is an object like: {"0" => "99.99", "1" => "89.99"}
        gross_price = product_data.dig("prices", "0")&.to_f

        return if sku.blank? && ean.blank? && name.blank?
        return if gross_price.nil? || gross_price.zero?

        # Find matching product in LiveCart using configured match method
        match_by = integration.price_match_by
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

        # Only update if price changed
        if product.gross_price.to_f != gross_price
          product.update!(gross_price: gross_price)
          log_success("Updated price for #{product.name}: #{product.gross_price} → #{gross_price}")
          stats[:updated_count] += 1
        else
          log_info("Price unchanged for #{product.name}: #{gross_price}")
        end
      rescue StandardError => e
        log_error("Error processing product price (SKU: #{sku}): #{e.message}")
        stats[:failed_count] += 1
        stats[:errors] << "SKU #{sku}: #{e.message}"
      end
    end
  end
end
