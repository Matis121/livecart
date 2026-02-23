module Integrations
  class BaseImporter
    attr_reader :integration, :account

    def initialize(integration)
      @integration = integration
      @account = integration.account
    end

    # Override in subclasses
    def call
      raise NotImplementedError, "Subclasses must implement #call"
    end

    # Class method for convenient calling
    def self.call(integration)
      new(integration).call
    end

    private

    # Track import statistics
    def track_stats
      stats = {
        updated_count: 0,
        failed_count: 0,
        errors: []
      }

      result = yield(stats)

      log_import_summary(stats)

      result
    rescue StandardError => e
      log_error("Import failed: #{e.message}")
      stats[:errors] << e.message
      Result.failure(
        errors: stats[:errors],
        message: "Import failed: #{e.message}"
      )
    end

    def log_import_summary(stats)
      Rails.logger.info("🎯 [#{integration.provider.upcase}] Import summary:")
      Rails.logger.info("✅ Updated: #{stats[:updated_count]}")
      Rails.logger.info("❌ Failed: #{stats[:failed_count]}")
      Rails.logger.info("❌ Errors: #{stats[:errors].join(', ')}") if stats[:errors].any?
    end

    def log_info(message)
      Rails.logger.info("🔵 [#{integration.provider.upcase}] #{message}")
    end

    def log_error(message)
      Rails.logger.error("❌ [#{integration.provider.upcase}] #{message}")
    end

    def log_success(message)
      Rails.logger.info("✅ [#{integration.provider.upcase}] #{message}")
    end
  end
end
