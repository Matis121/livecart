module Integrations
  class BaselinkerPriceSyncWorker
    include Sidekiq::Worker

    sidekiq_options queue: :default, retry: 3

    def perform
      Rails.logger.info "[CRON] Starting scheduled Baselinker price sync..."

      Integration.active.for_provider("baselinker").find_each do |integration|
        Rails.logger.info "[CRON] Queuing price sync for Baselinker integration ##{integration.id}"
        Integrations::BaselinkerPriceSyncJob.perform_later(integration.id)
      end

      Rails.logger.info "✅ [CRON] Scheduled Baselinker price sync completed"
    rescue StandardError => e
      Rails.logger.error "❌ [CRON] Failed to schedule Baselinker price sync: #{e.message}"
      raise
    end
  end
end
