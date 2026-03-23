module Integrations
  module Tiktok
    class AuthService
      AUTHORIZE_URL = "https://www.tiktok.com/v2/auth/authorize/"
      TOKEN_URL     = "https://open.tiktokapis.com/v2/oauth/token/"
      USER_INFO_URL = "https://open.tiktokapis.com/v2/user/info/"
      SCOPES        = "user.info.basic"
      # SCOPES        = "user.info.basic,live.room.info,live.room.chat.read,message.send"
      CACHE_TTL     = 10.minutes

      attr_reader :client_key, :client_secret, :redirect_uri

      def initialize
        @client_key    = Rails.application.credentials.dig(:tiktok, :client_key)
        @client_secret = Rails.application.credentials.dig(:tiktok, :client_secret)
        @redirect_uri  = Rails.application.credentials.dig(:tiktok, :redirect_uri) || begin
          url_options = Rails.application.config.action_mailer.default_url_options || {}
          Rails.application.routes.url_helpers.integrations_tiktok_oauth_callback_url(**url_options)
        end
      end

      # Step 1: generate PKCE params and return the authorization URL
      def authorization_url(state)
        code_verifier  = generate_code_verifier
        code_challenge = generate_code_challenge(code_verifier)

        Rails.cache.write(cache_key(state), code_verifier, expires_in: CACHE_TTL)

        params = {
          client_key:            client_key,
          scope:                 SCOPES,
          response_type:         "code",
          redirect_uri:          redirect_uri,
          state:                 state,
          code_challenge:        code_challenge,
          code_challenge_method: "S256"
        }

        "#{AUTHORIZE_URL}?#{params.to_query}"
      end

      # Step 2: exchange authorization code for tokens
      def exchange_code(code, state)
        code_verifier = Rails.cache.read(cache_key(state))
        raise AuthError, "Invalid or expired OAuth state" if code_verifier.nil?

        Rails.cache.delete(cache_key(state))

        response = Faraday.post(TOKEN_URL) do |req|
          req.headers["Content-Type"] = "application/x-www-form-urlencoded"
          req.body = URI.encode_www_form(
            client_key:    client_key,
            client_secret: client_secret,
            code:          code,
            grant_type:    "authorization_code",
            redirect_uri:  redirect_uri,
            code_verifier: code_verifier
          )
        end

        parse_token_response(response)
      end

      # Refresh an existing access token
      def refresh_token(refresh_token_value)
        response = Faraday.post(TOKEN_URL) do |req|
          req.headers["Content-Type"] = "application/x-www-form-urlencoded"
          req.body = URI.encode_www_form(
            client_key:    client_key,
            client_secret: client_secret,
            grant_type:    "refresh_token",
            refresh_token: refresh_token_value
          )
        end

        parse_token_response(response)
      end

      # Fetch basic user info using an access token
      def fetch_user_info(access_token)
        response = Faraday.get(USER_INFO_URL) do |req|
          req.headers["Authorization"] = "Bearer #{access_token}"
          req.params["fields"] = "open_id,display_name,avatar_url"
        end

        body = JSON.parse(response.body)

        error = body["error"]
        if error.present? && error.is_a?(Hash) && error["code"] != "ok"
          raise AuthError, error["message"].presence || "User info fetch failed"
        end

        body.dig("data", "user") || {}
      end

      def generate_state
        SecureRandom.hex(16)
      end

      private

      def generate_code_verifier
        SecureRandom.urlsafe_base64(64).tr("=", "").first(128)
      end

      def generate_code_challenge(verifier)
        digest = OpenSSL::Digest::SHA256.digest(verifier)
        Base64.urlsafe_encode64(digest, padding: false)
      end

      def parse_token_response(response)
        body = JSON.parse(response.body)

        if body["error"].present?
          msg = body["error_description"] || body.dig("error", "message") || body["error"]
          raise AuthError, msg
        end

        {
          access_token:  body["access_token"],
          refresh_token: body["refresh_token"],
          expires_in:    body["expires_in"].to_i,
          open_id:       body["open_id"],
          scope:         body["scope"]
        }
      end

      def cache_key(state)
        "tiktok_oauth_state_#{state}"
      end

      class AuthError < StandardError; end
    end
  end
end
