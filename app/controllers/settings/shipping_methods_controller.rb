# app/controllers/settings/shipping_methods_controller.rb
module Settings
  class ShippingMethodsController < ApplicationController
    before_action :authenticate_user!
    before_action :set_shipping_method, only: [ :edit, :update, :destroy ]

    def index
      per_page = (params[:per_page] || 10).to_i
      @per_page_options = [ 10, 25, 50 ]
      @pagy, @shipping_methods = pagy(current_account.shipping_methods.order(:position), limit: per_page)
    end

    def new
      @shipping_method = ShippingMethod.new
    end

    def create
      @shipping_method = current_account.shipping_methods.build(shipping_method_params)
      if @shipping_method.save
        redirect_to settings_shipping_methods_path, notice: "Utworzono metodę wysyłki"
      else
        render turbo_stream: turbo_stream.replace("shipping_method_modal", template: "settings/shipping_methods/new")
      end
    end

    def edit
    end

    def update
      if @shipping_method.update(shipping_method_params)
        redirect_to settings_shipping_methods_path, notice: "Zaktualizowano metodę wysyłki"
      else
        render turbo_stream: turbo_stream.replace("shipping_method_modal", template: "settings/shipping_methods/edit")
      end
    end

    def destroy
      @shipping_method.destroy
      redirect_to settings_shipping_methods_path, notice: "Usunięto metodę wysyłki"
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
