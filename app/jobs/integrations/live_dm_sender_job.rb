module Integrations
  class LiveDmSenderJob < ApplicationJob
    queue_as :default
    sidekiq_options retry: 2

    def perform(transmission_id)
      transmission = Transmission.find_by(id: transmission_id)
      return unless transmission

      Integrations::LiveDmSender.new(transmission).call
    rescue StandardError => e
      Rails.logger.error("[LiveDmSenderJob] #{e.class}: #{e.message}")
      raise
    end
  end
end
