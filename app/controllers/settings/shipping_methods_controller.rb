# app/controllers/settings/shipping_methods_controller.rb
module Settings
  class ShippingMethodsController < ApplicationController
    before_action :authenticate_user!
    before_action :set_shipping_method, only: [ :edit, :update, :destroy ]

    def index
      @shipping_methods = current_account.shipping_methods.order(:position)
    end

    def new
      @shipping_method = ShippingMethod.new
    end

    def create
      @shipping_method = current_account.shipping_methods.build(shipping_method_params)
      if @shipping_method.save
        redirect_to settings_shipping_methods_path, notice: "Metoda wysyłki została utworzona"
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @shipping_method.update(shipping_method_params)
        redirect_to settings_shipping_methods_path, notice: "Metoda wysyłki została zaktualizowana"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @shipping_method.destroy
      redirect_to settings_shipping_methods_path, notice: "Metoda wysyłki została usunięta"
    end

    private

    def set_shipping_method
      @shipping_method = current_account.shipping_methods.find(params[:id])
    end

    def shipping_method_params
      params.require(:shipping_method).permit(:name, :price, :free_above, :is_pickup_point, :pickup_point_provider, :position, :active)
    end
  end
end
