require "csv"

module Products
  class CsvExporter
    def self.call(products)
      new(products).call
    end

    def initialize(products)
      @products = products
    end

    def call
      CSV.generate(headers: true) do |csv|
        csv << headers

        @products.find_each do |product|
          csv << product_row(product)
        end
      end
    end

    private

    def headers
      [
        "sku",
        "ean",
        "name",
        "gross_price",
        "tax_rate",
        "currency",
        "stock_quantity",
        "image_urls"
      ]
    end

    def product_row(product)
      [
        product.sku,
        product.ean,
        product.name,
        product.gross_price,
        product.tax_rate,
        product.currency,
        product.product_stock&.quantity || 0,
        image_urls(product)
      ]
    end

    def image_urls(product)
      return "" unless product.images.attached?

      urls = product.images.map do |image|
        Rails.application.routes.url_helpers.rails_blob_url(image, host: default_url_options[:host])
      end

      urls.join("|")
    end

    def default_url_options
      # Use configured URL options or fallback to defaults
      Rails.application.config.action_mailer.default_url_options || { host: "localhost:3000" }
    end
  end
end
