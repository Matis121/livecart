require "open-uri"

module Products
  class AttachImagesFromUrlsJob < ApplicationJob
    queue_as :default
    sidekiq_options retry: 2

    MAX_IMAGE_SIZE = 5.megabytes
    ALLOWED_CONTENT_TYPES = %w[image/png image/jpeg image/jpg].freeze

    def perform(product_id, image_urls)
      product = Product.find(product_id)

      image_urls.each_with_index do |url, index|
        attach_image_from_url(product, url, index)
      rescue StandardError => e
        Rails.logger.error(
          "Failed to attach image from URL '#{url}' for product #{product_id}: #{e.message}"
        )
        # Continue with next image instead of failing the entire job
      end
    end

    private

    def attach_image_from_url(product, url, index)
      URI.open(url, "rb", read_timeout: 10, redirect: true) do |file|
        # Validate content type
        content_type = file.content_type
        unless ALLOWED_CONTENT_TYPES.include?(content_type)
          raise "Invalid content type: #{content_type}"
        end

        content = file.read

        if content.bytesize > MAX_IMAGE_SIZE
          raise "Image too large: #{content.bytesize} bytes"
        end

        filename = generate_filename(url, index, content_type)
        product.images.attach(
          io: StringIO.new(content),
          filename: filename,
          content_type: content_type
        )

        Rails.logger.info(
          "Successfully attached image '#{filename}' to product #{product.id}"
        )
      end
    end

    def generate_filename(url, index, content_type)
      extension = content_type.split("/").last
      original_filename = File.basename(URI.parse(url).path)

      if original_filename.present? && original_filename != "/"
        original_filename
      else
        "image_#{index + 1}.#{extension}"
      end
    end
  end
end
