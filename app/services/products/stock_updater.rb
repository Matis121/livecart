module Products
  # Service for updating product stock from external integrations
  # Uses ProductStock#adjust_quantity! with proper movement tracking
  #
  # Usage:
  #   result = Products::StockUpdater.call(
  #     product: product,
  #     new_quantity: 100,
  #     source: :baselinker_import
  #   )
  class StockUpdater
    Result = Struct.new(:success?, :errors, :message, keyword_init: true) do
      def self.success(message: nil)
        new(success?: true, errors: [], message: message)
      end

      def self.failure(errors: [], message: nil)
        errors = [ errors ] unless errors.is_a?(Array)
        new(success?: false, errors: errors, message: message)
      end
    end

    def self.call(product:, new_quantity:, source: :integration_import)
      new(product: product, new_quantity: new_quantity, source: source).call
    end

    def initialize(product:, new_quantity:, source:)
      @product = product
      @new_quantity = new_quantity.to_i
      @source = source
    end

    def call
      return Result.failure(errors: [ "Product not found" ]) unless @product
      return Result.failure(errors: [ "Invalid quantity" ]) if @new_quantity.negative?

      product_stock = @product.product_stock

      unless product_stock
        return Result.failure(errors: [ "Product stock record not found" ])
      end

      # Skip if quantity is the same
      if product_stock.quantity == @new_quantity
        return Result.success(message: "Stock unchanged (#{@new_quantity})")
      end

      old_quantity = product_stock.quantity

      # Use ProductStock#adjust_quantity! which handles locking and movement tracking
      product_stock.adjust_quantity!(@new_quantity)
      product_stock.update!(last_synced_at: Time.current, sync_enabled: true)

      Result.success(
        message: "Stock updated: #{old_quantity} → #{@new_quantity}"
      )
    rescue ActiveRecord::RecordInvalid => e
      Result.failure(errors: [ e.message ])
    rescue StandardError => e
      Rails.logger.error("StockUpdater error: #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))
      Result.failure(errors: [ "Failed to update stock: #{e.message}" ])
    end
  end
end
