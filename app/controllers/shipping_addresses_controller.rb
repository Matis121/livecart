class ShippingAddressesController < ApplicationController
  before_action :set_order
  before_action :set_shipping_address

  def edit
  end

  def update
    if @shipping_address.update(shipping_address_params)
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.update("shipping_address_modal", ""),
            turbo_stream.replace(
              "shipping_address_section",
              partial: "orders/shipping_address_section",
              locals: { order: @order, shipping_address: @shipping_address }
            )
          ]
        end
        format.html { redirect_to @order, notice: "Adres dostawy został zaktualizowany" }
      end
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def copy_from_billing
    billing_address = @order.billing_address
    
    if billing_address.present?
      @shipping_address.update(billing_address_values(billing_address))
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "shipping_address_section",
            partial: "orders/shipping_address_section",
            locals: { order: @order, shipping_address: @shipping_address }
          )
        end
        format.html { redirect_to @order, notice: "Skopiowano dane z adresu faktury" }
      end
    else
      redirect_to @order, alert: "Brak adresu faktury do skopiowania"
    end
  end

  private

  def set_order
    @order = current_account.orders.find_by!(order_number: params[:order_id])
  end

  def set_shipping_address
    @shipping_address = @order.shipping_address || @order.build_shipping_address
  end

  def billing_address_values(billing_address)
    {
      first_name: billing_address.first_name,
      last_name: billing_address.last_name,
      address_line1: billing_address.address_line1,
      address_line2: billing_address.address_line2,
      city: billing_address.city,
      postal_code: billing_address.postal_code,
      country: billing_address.country
    }
  end

  def shipping_address_params
    params.require(:shipping_address).permit(
      :first_name,
      :last_name,
      :address_line1,
      :address_line2,
      :city,
      :postal_code,
      :country
    )
  end
end
