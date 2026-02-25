module Settings
  class DiscountsController < ApplicationController
    before_action :authenticate_user!
    before_action :set_discount_code, only: [ :destroy, :update ]
    def index
      per_page = (params[:per_page] || 10).to_i
      @per_page_options = [ 10, 25, 50 ]
      @pagy, @discount_codes = pagy(current_account.discount_codes.order(created_at: :desc), limit: per_page)
    end

    def new
      @discount_code = DiscountCode.new
    end

    def create
      @discount_code = current_account.discount_codes.build(discount_code_params)
      if @discount_code.save
        redirect_to settings_discounts_path, notice: "Utworzono kod rabatowy"
      else
        render turbo_stream: turbo_stream.replace("discount_modal", template: "settings/discounts/new")
      end
    end

    def update
      @discount_code.active = !@discount_code.active
      if @discount_code.save
        redirect_to settings_discounts_path, notice: "Zaktualizowano kod rabatowy"
      else
        redirect_to settings_discounts_path, alert: "Nie udało się zaktualizować kodu rabatowego"
      end
    end

    def destroy
      @discount_code.destroy
      redirect_to settings_discounts_path, notice: "Usunięto kod rabatowy"
    end

    private

    def set_discount_code
      @discount_code = current_account.discount_codes.find(params[:id])
    end

    def discount_code_params
      params.require(:discount_code).permit(:code, :name, :description, :discount_type, :value, :minimum_order_amount, :free_shipping, :valid_from, :valid_until, :usage_limit, :active, :kind)
    end
  end
end
