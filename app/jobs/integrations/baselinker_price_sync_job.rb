module Integrations
  class BaselinkerPriceSyncJob < ApplicationJob
    queue_as :default
    sidekiq_options retry: 3

    def perform(integration_id)
      integration = Integration.find(integration_id)

      unless integration.status_active?
        Rails.logger.info("🔵 Baselinker price sync skipped - integration not active (ID: #{integration_id})")
        return
      end

      unless integration.can_sync?
        Rails.logger.warn("⚠️ Baselinker price sync skipped - missing credentials (ID: #{integration_id})")
        return
      end

      unless integration.price_sync_enabled?
        Rails.logger.info("⏭️  Price sync disabled - skipping (ID: #{integration_id})")
        return
      end

      Rails.logger.info("🚀 Starting Baselinker price sync for account: #{integration.account.company_name}")

      result = Baselinker::PriceImporter.call(integration)

      if result.success?
        Rails.logger.info("✅ Price import: #{result.message}")
        Rails.logger.info("Prices: #{result.updated_count} updated, #{result.failed_count} failed")
      else
        Rails.logger.error("❌ Price import failed: #{result.errors.join(', ')}")
      end
    rescue StandardError => e
      Rails.logger.error("❌ Baselinker price sync failed: #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))

      integration&.mark_sync_error!(e.message)
      raise
    end
  end
end
