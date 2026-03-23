module Integrations
  class TiktokOauthController < ApplicationController
    def authorize
      auth_service = Integrations::Tiktok::AuthService.new
      state = auth_service.generate_state

      # Store state in session for extra CSRF protection
      session[:tiktok_oauth_state] = state

      redirect_to auth_service.authorization_url(state), allow_other_host: true
    end

    def callback
      if params[:error].present?
        redirect_to integrations_path, alert: "TikTok OAuth error: #{params[:error_description]}"
        return
      end

      unless params[:state].present? && params[:state] == session[:tiktok_oauth_state]
        redirect_to integrations_path, alert: "Nieprawidłowy stan OAuth. Spróbuj ponownie."
        return
      end

      session.delete(:tiktok_oauth_state)

      auth_service = Integrations::Tiktok::AuthService.new

      begin
        tokens    = auth_service.exchange_code(params[:code], params[:state])
        user_info = auth_service.fetch_user_info(tokens[:access_token])

        upsert_integration!(tokens, user_info)

        redirect_to integrations_path, notice: "Konto TikTok zostało pomyślnie połączone jako @#{user_info["display_name"]}."
      rescue Integrations::Tiktok::AuthService::AuthError => e
        redirect_to integrations_path, alert: "Błąd połączenia z TikTok: #{e.message}"
      end
    end

    private

    def upsert_integration!(tokens, user_info)
      integration = current_account.integrations.find_or_initialize_by(provider: "tiktok")
      integration.assign_attributes(
        user:                 current_user,
        integration_type:     :social_media,
        access_token:         tokens[:access_token],
        refresh_token:        tokens[:refresh_token],
        token_expires_at:     Time.current + tokens[:expires_in].seconds,
        provider_uid:         tokens[:open_id],
        provider_account_name: user_info["display_name"],
        status:               "active",
        last_error_message:   nil
      )
      integration.save!
    end
  end
end
