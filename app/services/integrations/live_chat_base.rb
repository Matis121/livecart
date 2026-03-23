module Integrations
  # Abstract base class for live chat platform integrations.
  # Each platform (TikTok, Instagram, Facebook) must implement this interface.
  class LiveChatBase
    attr_reader :integration

    def initialize(integration)
      @integration = integration
    end

    # Fetch new chat messages since the given cursor.
    # Returns { messages: Array<Hash>, next_cursor: String }
    # Each message hash: { message_id:, user_id:, username:, avatar_url:, text:, created_at: }
    def fetch_messages(room_id, cursor: nil)
      raise NotImplementedError, "#{self.class} must implement #fetch_messages"
    end

    # Send a direct message to a platform user.
    def send_dm(to_user_id, text)
      raise NotImplementedError, "#{self.class} must implement #send_dm"
    end

    # Resolve a platform live external ID to the room ID used for chat.
    # Some platforms (e.g. TikTok) distinguish between the public live ID and the internal room ID.
    def get_room_id(live_external_id)
      raise NotImplementedError, "#{self.class} must implement #get_room_id"
    end

    # Poll for new messages and broadcast them to Action Cable.
    def poll_and_broadcast(transmission)
      cursor  = integration.live_cursor_for(transmission.id)
      result  = fetch_messages(transmission.live_room_id, cursor: cursor)
      messages = result[:messages]

      return if messages.empty?

      messages.each do |msg|
        ActionCable.server.broadcast(
          "live_chat_transmission_#{transmission.id}",
          msg.merge(platform: integration.provider)
        )
      end

      integration.update_live_cursor!(transmission.id, result[:next_cursor]) if result[:next_cursor].present?
    end
  end
end
