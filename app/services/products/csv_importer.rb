require "csv"

module Products
  class CsvImporter
    STRATEGIES = %w[import_all skip_duplicate_sku skip_duplicate_ean skip_duplicate_name].freeze
    REQUIRED_HEADERS = %w[name gross_price].freeze
    OPTIONAL_HEADERS = %w[sku ean tax_rate currency stock_quantity image_urls].freeze

    Result = Struct.new(:success_count, :skipped_count, :error_count, :skipped_rows, :errors, keyword_init: true) do
      def success?
        error_count.zero?
      end

      def total_processed
        success_count + skipped_count + error_count
      end
    end

    def self.call(csv_file, account:, duplicate_strategy:)
      new(csv_file, account: account, duplicate_strategy: duplicate_strategy).call
    end

    def initialize(csv_file, account:, duplicate_strategy:)
      @csv_file = csv_file
      @account = account
      @duplicate_strategy = duplicate_strategy
      @success_count = 0
      @skipped_count = 0
      @error_count = 0
      @skipped_rows = []
      @errors = []
    end

    def call
      validate_strategy!

      csv_data = CSV.parse(@csv_file.read, headers: true, header_converters: :symbol)
      validate_headers!(csv_data.headers)

      csv_data.each_with_index do |row, index|
        row_number = index + 2 # +2 because of 0-index and header row
        process_row(row, row_number)
      end

      Result.new(
        success_count: @success_count,
        skipped_count: @skipped_count,
        error_count: @error_count,
        skipped_rows: @skipped_rows,
        errors: @errors
      )
    rescue CSV::MalformedCSVError => e
      Result.new(
        success_count: 0,
        skipped_count: 0,
        error_count: 1,
        skipped_rows: [],
        errors: [ { row: 0, messages: [ "Nieprawidłowy format CSV: #{e.message}" ] } ]
      )
    end

    private

    def validate_strategy!
      unless STRATEGIES.include?(@duplicate_strategy)
        raise ArgumentError, "Invalid duplicate strategy: #{@duplicate_strategy}"
      end
    end

    def validate_headers!(headers)
      missing_headers = REQUIRED_HEADERS - headers.map(&:to_s)

      if missing_headers.any?
        raise ArgumentError, "Brakujące wymagane kolumny: #{missing_headers.join(', ')}"
      end
    end

    def process_row(row, row_number)
      if should_skip_duplicate?(row)
        @skipped_count += 1
        @skipped_rows << { row: row_number, reason: skip_reason(row) }
        return
      end

      create_product(row, row_number)
    rescue ActiveRecord::RecordInvalid => e
      @error_count += 1
      @errors << { row: row_number, messages: e.record.errors.full_messages }
    rescue StandardError => e
      @error_count += 1
      @errors << { row: row_number, messages: [ e.message ] }
    end

    def should_skip_duplicate?(row)
      case @duplicate_strategy
      when "import_all"
        false
      when "skip_duplicate_sku"
        row[:sku].present? && @account.products.exists?(sku: row[:sku])
      when "skip_duplicate_ean"
        row[:ean].present? && @account.products.exists?(ean: row[:ean])
      when "skip_duplicate_name"
        row[:name].present? && @account.products.exists?(name: row[:name])
      end
    end

    def skip_reason(row)
      case @duplicate_strategy
      when "skip_duplicate_sku"
        "SKU '#{row[:sku]}' już istnieje"
      when "skip_duplicate_ean"
        "EAN '#{row[:ean]}' już istnieje"
      when "skip_duplicate_name"
        "Nazwa '#{row[:name]}' już istnieje"
      end
    end

    def create_product(row, row_number)
      product = nil

      ApplicationRecord.transaction do
        product = @account.products.build(product_attributes(row))
        product.save!

        product.create_product_stock!(quantity: 0) unless product.product_stock

        if row[:stock_quantity].present?
          stock_quantity = row[:stock_quantity].to_i
          product.product_stock.adjust_quantity!(stock_quantity)
        end

        @success_count += 1
      end

      if row[:image_urls].present? && product
        image_urls = row[:image_urls].split("|").map(&:strip)
        Products::AttachImagesFromUrlsJob.perform_later(product.id, image_urls)
      end
    end

    def product_attributes(row)
      {
        sku: row[:sku],
        ean: row[:ean],
        name: row[:name],
        gross_price: row[:gross_price],
        tax_rate: row[:tax_rate] || 23,
        currency: row[:currency] || "PLN"
      }
    end
  end
end
