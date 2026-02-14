module Products
  class ImportCoordinator
    SYNC_THRESHOLD = 50

    def initialize(account:, csv_file:, duplicate_strategy:)
      @account = account
      @csv_file = csv_file
      @duplicate_strategy = duplicate_strategy
    end

    def call
      validate_csv!
      create_import_record!

      if sync_processing?
        process_synchronously
      else
        process_asynchronously
      end
    end

    private

    attr_reader :account, :csv_file, :duplicate_strategy, :product_import

    def validate_csv!
      max_size = 5.megabytes
      if csv_file.size > max_size
        raise ValidationError, "Plik jest za duży (max #{max_size / 1.megabyte}MB)"
      end

      @row_count = count_csv_rows(csv_file)
    rescue CSV::MalformedCSVError => e
      raise ValidationError, "Nieprawidłowy format CSV: #{e.message}"
    rescue ArgumentError => e
      raise ValidationError, "Błąd parsowania CSV: #{e.message}"
    end

    def create_import_record!
      @product_import = account.product_imports.create!(
        import_name: "Produkty - CSV",
        duplicate_strategy: duplicate_strategy,
        status: :pending,
        total_rows: @row_count
      )
    end

    def sync_processing?
      @row_count <= SYNC_THRESHOLD
    end

    def process_synchronously
      csv_file.rewind
      product_import.update!(status: :processing)

      result = Products::CsvImporter.call(
        csv_file,
        account: account,
        duplicate_strategy: duplicate_strategy
      )

      product_import.update!(
        status: :completed,
        success_count: result.success_count,
        skipped_count: result.skipped_count,
        error_count: result.error_count,
        error_details: result.errors
      )

      {
        success: true,
        message: "Import został rozpoczęty"
      }
    end

    def process_asynchronously
      temp_file = save_temp_file(csv_file)
      Products::ImportCsvJob.perform_later(
        account.id,
        temp_file.path,
        duplicate_strategy,
        product_import.id
      )

      {
        success: true,
        message: "Import został rozpoczęty"
      }
    end

    def count_csv_rows(file)
      file.rewind
      row_count = 0

      CSV.foreach(file.path, headers: true) do |row|
        row_count += 1
        raise ValidationError, "Plik przekracza maksymalny limit 10000 wierszy" if row_count > 10_000
      end

      file.rewind
      row_count
    end

    def save_temp_file(uploaded_file)
      temp_file = Tempfile.new([ "csv_import", ".csv" ])
      temp_file.binmode
      uploaded_file.rewind
      temp_file.write(uploaded_file.read)
      temp_file.close
      temp_file
    end


    class ValidationError < StandardError; end
  end
end
