module Integrations
  class ExportOrderJob < ApplicationJob
    queue_as :default
    sidekiq_options retry: 3

    def perform(order_id, integration_id)
      order = Order.find(order_id)
      integration = Integration.find(integration_id)

      unless integration.status_active?
        Rails.logger.info("🔵 Order export skipped - integration not active")
        return
      end

      unless integration.type_marketplace?
        Rails.logger.warn("⚠️ Order export skipped - integration is not a marketplace type")
        return
      end

      Rails.logger.info("🚀 Exporting order #{order.order_number} to #{integration.provider_name}")

      # Call appropriate exporter based on provider
      result = case integration.provider.downcase
      when "baselinker"
        Baselinker::OrderExporter.call(integration, order)
      when "sellasist"
        # Sellasist::OrderExporter.call(integration, order) # Future implementation
        Rails.logger.warn("⚠️ Sellasist exporter not yet implemented")
        return
      else
        Rails.logger.error("❌ Unknown provider: #{integration.provider}")
        return
      end

      if result.success?
        Rails.logger.info("✅ Order #{order.order_number} exported successfully")
        Rails.logger.info("   External ID: #{result.data[:baselinker_order_id]}") if result.data
      else
        Rails.logger.error("❌ Order export failed: #{result.errors.join(', ')}")
        raise StandardError, "Order export failed: #{result.errors.join(', ')}"
      end
    rescue ActiveRecord::RecordNotFound => e
      Rails.logger.error("❌ Record not found: #{e.message}")
      # Don't retry on not found
    rescue StandardError => e
      Rails.logger.error("❌ Order export error: #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))
      raise # Re-raise for Sidekiq retry
    end
  end
end
