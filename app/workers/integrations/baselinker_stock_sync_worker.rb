module Integrations
  class BaselinkerStockSyncWorker
    include Sidekiq::Worker

    sidekiq_options queue: :default, retry: 3

    def perform
      Rails.logger.info "[CRON] Starting scheduled Baselinker stock sync..."

      Integration.active.for_provider('baselinker').find_each do |integration|
        Rails.logger.info "[CRON] Queuing stock sync for Baselinker integration ##{integration.id}"
        Integrations::BaselinkerStockSyncJob.perform_later(integration.id)
      end

      Rails.logger.info "✅ [CRON] Scheduled Baselinker stock sync completed"
    rescue StandardError => e
      Rails.logger.error "❌ [CRON] Failed to schedule Baselinker stock sync: #{e.message}"
      raise
    end
  end
end
