module Settings
  class PaymentMethodsController < ApplicationController
    before_action :authenticate_user!
    before_action :set_payment_method, only: [ :edit, :update, :destroy ]

    def index
      @payment_methods = current_account.payment_methods.order(:position)
    end

    def new
      @payment_method = PaymentMethod.new
      @payment_integrations = payment_integrations
    end

    def create
      @payment_method = current_account.payment_methods.build(payment_method_params)
      if @payment_method.save
        redirect_to settings_payment_methods_path, notice: "Utworzono metodę płatności"
      else
        @payment_integrations = payment_integrations
        render turbo_stream: turbo_stream.replace("payment_method_modal", template: "settings/payment_methods/new")
      end
    end

    def edit
      @payment_integrations = payment_integrations
    end

    def update
      if @payment_method.update(payment_method_params)
        redirect_to settings_payment_methods_path, notice: "Zaktualizowano metodę płatności"
      else
        @payment_integrations = payment_integrations
        render turbo_stream: turbo_stream.replace("payment_method_modal", template: "settings/payment_methods/edit")
      end
    end

    def destroy
      @payment_method.destroy
      redirect_to settings_payment_methods_path, notice: "Usunięto metodę płatności"
    end

    private

    def set_payment_method
      @payment_method = current_account.payment_methods.find(params[:id])
    end

    def payment_method_params
      params.require(:payment_method).permit(:name, :description, :integration_id, :position, :active, :cash_on_delivery)
    end

    def payment_integrations
      current_account.integrations.where(integration_type: :payment)
    end
  end
end
