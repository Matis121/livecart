class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :require_account
  before_action :authenticate_user!

  helper_method :current_account, :onboarding_complete?, :public_checkout_page?

  private

  def current_account
    @current_account ||= current_user&.account
  end

  def onboarding_complete?
    current_account.present?
  end

  def public_checkout_page?
    controller_name == "checkouts"
  end

  def require_account
    return unless user_signed_in?
    return if devise_controller?
    redirect_to new_onboarding_account_path if current_user.account.blank?
  end
end
