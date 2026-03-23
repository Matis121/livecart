module Integrations
  module Tiktok
    class LiveChatPoller < Integrations::LiveChatBase
      # Fetch new messages from TikTok live chat.
      # TikTok LIVE API uses cursor-based pagination.
      # NOTE: Requires LIVE API approval from TikTok (developer.tiktok.com → Products → LIVE).
      def fetch_messages(room_id, cursor: nil)
        client = Integrations::Tiktok::Client.new(integration)
        response = client.fetch_chat_messages(room_id, cursor: cursor)

        data = response.dig("data") || {}
        raw_messages = data.dig("comments") || []
        next_cursor  = data.dig("cursor")

        messages = raw_messages.map do |msg|
          {
            message_id: msg["msg_id"],
            user_id:    msg.dig("user", "open_id"),
            username:   msg.dig("user", "display_name"),
            avatar_url: msg.dig("user", "avatar_url"),
            text:       msg["content"],
            created_at: Time.at(msg["create_time"].to_i).iso8601
          }
        end

        { messages: messages, next_cursor: next_cursor }
      rescue Integrations::IntegrationError => e
        Rails.logger.error("[TikTok LiveChatPoller] #{e.message}")
        { messages: [], next_cursor: cursor }
      end

      def get_room_id(live_external_id)
        client   = Integrations::Tiktok::Client.new(integration)
        response = client.get_live_room_info(live_external_id)
        response.dig("data", "room_id")
      end

      def send_dm(to_user_id, text)
        client = Integrations::Tiktok::Client.new(integration)
        client.send_dm(to_user_id, text)
      end
    end
  end
end
