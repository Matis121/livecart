module Settings
  class DiscountController < ApplicationController
    before_action :authenticate_user!
    before_action :set_discount_code, only: [ :destroy, :update ]
    def index
      @discount_codes = current_account.discount_codes
    end

    def new
      @discount_code = DiscountCode.new
    end

    def create
      @discount_code = current_account.discount_codes.build(discount_code_params)
      if @discount_code.save
        redirect_to settings_discount_index_path, notice: "Kod rabatowy został utworzony"
      else
        render :new, status: :unprocessable_entity
      end
    end

    def update
      @discount_code.active = !@discount_code.active
      if @discount_code.save
        redirect_to settings_discount_index_path, notice: "Kod rabatowy został zaktualizowany"
      else
        redirect_to settings_discount_index_path, alert: "Nie udało się zaktualizować statusu kodu rabatowego"
      end
    end

    def destroy
      @discount_code.destroy
      redirect_to settings_discount_path, notice: "Kod rabatowy został usunięty"
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
