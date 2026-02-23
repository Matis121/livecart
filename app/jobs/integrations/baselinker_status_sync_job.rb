module Integrations
  class BaselinkerStatusSyncJob < ApplicationJob
    queue_as :default
    sidekiq_options retry: 3

    def perform(integration_id)
      integration = Integration.find(integration_id)

      unless integration.status_active?
        Rails.logger.info("🔵 Baselinker status sync skipped - integration not active (ID: #{integration_id})")
        return
      end

      unless integration.can_sync?
        Rails.logger.warn("⚠️ Baselinker status sync skipped - missing credentials (ID: #{integration_id})")
        return
      end

      unless integration.order_status_sync_enabled?
        Rails.logger.info("⏭️  Order status sync disabled - skipping (ID: #{integration_id})")
        return
      end

      Rails.logger.info("🚀 Starting Baselinker order status sync for account: #{integration.account.company_name}")

      result = Baselinker::OrderStatusImporter.call(integration)

      if result.success?
        Rails.logger.info("✅ Order status import: #{result.message}")
        Rails.logger.info("Order statuses: #{result.updated_count} updated, #{result.failed_count} failed")
      else
        Rails.logger.error("❌ Order status import failed: #{result.errors.join(', ')}")
      end
    rescue StandardError => e
      Rails.logger.error("❌ Baselinker status sync failed: #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))

      integration&.mark_sync_error!(e.message)
      raise
    end
  end
end
