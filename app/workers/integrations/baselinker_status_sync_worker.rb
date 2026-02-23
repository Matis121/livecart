module Integrations
  class BaselinkerStatusSyncWorker
    include Sidekiq::Worker

    sidekiq_options queue: :default, retry: 3

    def perform
      Rails.logger.info "[CRON] Starting scheduled Baselinker status sync..."

      Integration.active.for_provider("baselinker").find_each do |integration|
        Rails.logger.info "[CRON] Queuing status sync for Baselinker integration ##{integration.id}"
        Integrations::BaselinkerStatusSyncJob.perform_later(integration.id)
      end

      Rails.logger.info "✅ [CRON] Scheduled Baselinker status sync completed"
    rescue StandardError => e
      Rails.logger.error "❌ [CRON] Failed to schedule Baselinker status sync: #{e.message}"
      raise
    end
  end
end
