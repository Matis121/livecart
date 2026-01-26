# app/controllers/settings/checkout_controller.rb
module Settings
  class CheckoutController < ApplicationController
    before_action :authenticate_user!

    def edit
      @account = current_account
      @checkout_settings = @account.checkout_settings || {}
    end

    def update
      @account = current_account

      if params[:account][:remove_logo] == "1"
        @account.logo.purge
      end

      if params[:account][:logo].present?
        @account.logo.attach(params[:account][:logo])
      end

      if @account.update(checkout_settings_params.except(:logo, :remove_logo))
        redirect_to settings_checkout_path, notice: "Ustawienia zostały zaktualizowane"
      else
        @checkout_settings = @account.checkout_settings || {}
        render :edit
      end
    end

    private

    def checkout_settings_params
      params.require(:account).permit(:name, :time_to_pay, :time_to_pay_active, :logo, :remove_logo)
    end
  end
end
