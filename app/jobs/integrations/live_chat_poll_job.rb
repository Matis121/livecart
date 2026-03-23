module Integrations
  class LiveChatPollJob < ApplicationJob
    queue_as :default
    sidekiq_options retry: 0  # No retries - we self-schedule, failures just skip one poll

    def perform(transmission_id, integration_id)
      transmission = Transmission.find_by(id: transmission_id)
      integration  = Integration.find_by(id: integration_id)

      return unless transmission&.active? && integration&.status_active?
      return unless transmission.live_room_id.present?

      poller_class = poller_for(integration.provider)
      return if poller_class.nil?

      poller = poller_class.new(integration)
      poller.poll_and_broadcast(transmission)

      # Self-schedule next poll
      self.class.set(wait: 5.seconds).perform_later(transmission_id, integration_id)
    rescue StandardError => e
      Rails.logger.error("[LiveChatPollJob] #{e.class}: #{e.message}")
      # Continue self-scheduling even on error so we don't stop the live feed
      self.class.set(wait: 10.seconds).perform_later(transmission_id, integration_id) if still_active?(transmission_id)
    end

    private

    def poller_for(provider)
      "Integrations::#{provider.capitalize}::LiveChatPoller".constantize
    rescue NameError
      Rails.logger.warn("[LiveChatPollJob] No poller found for provider: #{provider}")
      nil
    end

    def still_active?(transmission_id)
      Transmission.find_by(id: transmission_id)&.active?
    end
  end
end
