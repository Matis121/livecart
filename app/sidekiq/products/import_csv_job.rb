module Products
  class ImportCsvJob < ApplicationJob
    queue_as :default
    sidekiq_options retry: 3

    def perform(account_id, csv_file_path, duplicate_strategy, product_import_id)
      account = Account.find(account_id)
      product_import = ProductImport.find(product_import_id)

      product_import.update!(status: :processing)

      File.open(csv_file_path, "r") do |file|
        result = Products::CsvImporter.call(
          file,
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
      end
    rescue => e
      product_import.update!(
        status: :failed,
        error_details: [ { error: e.message, backtrace: e.backtrace.first(5) } ]
      )
      raise
    ensure
      File.delete(csv_file_path) if File.exist?(csv_file_path)
    end

    private

    def log_import_result(account_id, result)
      Rails.logger.info(
        "CSV Import completed for account #{account_id}: " \
        "#{result.success_count} successful, " \
        "#{result.skipped_count} skipped, " \
        "#{result.error_count} errors"
      )

      if result.skipped_rows.any?
        Rails.logger.info("Skipped rows: #{result.skipped_rows.inspect}")
      end

      if result.errors.any?
        Rails.logger.warn("Import errors: #{result.errors.inspect}")
      end
    end
  end
end
