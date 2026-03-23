module Integrations
  module Tiktok
    class Client < Integrations::BaseClient
      BASE_URL = "https://open.tiktokapis.com"

      def initialize(integration)
        super(base_url: BASE_URL, integration: integration)
      end

      # Get live room info - returns room_id needed for chat polling.
      # Requires live.room.info scope.
      def get_live_room_info(live_external_id)
        ensure_fresh_token!
        get("/v2/live/room/info/", { fields: "room_id,status,title", live_id: live_external_id })
      end

      # Fetch chat messages from a live room.
      # Requires live.room.chat.read scope (LIVE API approval needed).
      def fetch_chat_messages(room_id, cursor: nil)
        ensure_fresh_token!
        params = { room_id: room_id, max_count: 50 }
        params[:cursor] = cursor if cursor.present?
        get("/v2/live/room/chat/", params)
      end

      # Get authenticated user's basic info.
      def get_user_info
        ensure_fresh_token!
        get("/v2/user/info/", { fields: "open_id,display_name,avatar_url" })
      end

      # Send a direct message to a TikTok user.
      # Requires message.send scope (enterprise partner approval needed).
      def send_dm(to_user_id, text)
        ensure_fresh_token!
        post("/v2/message/send/", { to_user_id: to_user_id, message_type: "text", content: { text: text } })
      end

      private

      def default_headers
        super.merge("Authorization" => "Bearer #{integration.access_token}")
      end

      def ensure_fresh_token!
        return unless integration.token_expiring_soon?

        auth_service = Integrations::Tiktok::AuthService.new
        tokens = auth_service.refresh_token(integration.refresh_token)

        integration.update_columns(
          access_token:     tokens[:access_token],
          refresh_token:    tokens[:refresh_token],
          token_expires_at: Time.current + tokens[:expires_in].seconds
        )
      end
    end
  end
end
