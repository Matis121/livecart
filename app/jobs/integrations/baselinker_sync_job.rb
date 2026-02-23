module Integrations
  class BaselinkerSyncJob < ApplicationJob
    queue_as :default
    sidekiq_options retry: 3

    def perform(integration_id)
      integration = Integration.find(integration_id)

      unless integration.status_active?
        Rails.logger.info("🔵 Baselinker sync skipped - integration not active (ID: #{integration_id})")
        return
      end

      unless integration.can_sync?
        Rails.logger.warn("⚠️ Baselinker sync skipped - missing credentials (ID: #{integration_id})")
        return
      end

      Rails.logger.info("🚀 Starting Baselinker sync for account: #{integration.account.company_name}")

      stock_result = nil
      price_result = nil
      order_status_result = nil

      # Import stock (if enabled)
      if integration.stock_sync_enabled?
        stock_result = Baselinker::StockImporter.call(integration)
        log_result("Stock", stock_result)
      else
        Rails.logger.info("⏭️  Stock sync disabled - skipping")
        stock_result = Result.success(message: "Skipped (disabled)", updated_count: 0, failed_count: 0)
      end

      # Import prices (if enabled)
      if integration.price_sync_enabled?
        price_result = Baselinker::PriceImporter.call(integration)
        log_result("Price", price_result)
      else
        Rails.logger.info("⏭️  Price sync disabled - skipping")
        price_result = Result.success(message: "Skipped (disabled)", updated_count: 0, failed_count: 0)
      end

      # Import order statuses from Baselinker (if enabled)
      if integration.order_status_sync_enabled?
        order_status_result = Baselinker::OrderStatusImporter.call(integration)
        log_result("Order status", order_status_result)
      else
        Rails.logger.info("⏭️  Order status sync disabled - skipping")
        order_status_result = Result.success(message: "Skipped (disabled)", updated_count: 0, failed_count: 0)
      end

      Rails.logger.info("✅ Baselinker sync completed")
      Rails.logger.info("Stock: #{stock_result.updated_count} updated, #{stock_result.failed_count} failed")
      Rails.logger.info("Prices: #{price_result.updated_count} updated, #{price_result.failed_count} failed")
      Rails.logger.info("Order statuses: #{order_status_result.updated_count} updated, #{order_status_result.failed_count} failed")
    rescue StandardError => e
      Rails.logger.error("❌ Baselinker sync failed: #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))

      integration&.mark_sync_error!(e.message)
      raise # Re-raise for Sidekiq retry
    end

    private

    def log_result(type, result)
      if result.success?
        Rails.logger.info("✅ #{type} import: #{result.message}")
      else
        Rails.logger.error("❌ #{type} import failed: #{result.errors.join(', ')}")
      end
    end
  end
end
