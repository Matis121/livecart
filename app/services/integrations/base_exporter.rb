module Integrations
  class BaseExporter
    attr_reader :integration, :account

    def initialize(integration)
      @integration = integration
      @account = integration.account
    end

    # Override in subclasses
    def call(resource)
      raise NotImplementedError, "Subclasses must implement #call"
    end

    # Class method for convenient calling
    def self.call(integration, resource)
      new(integration).call(resource)
    end

    private

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
