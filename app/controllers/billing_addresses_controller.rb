class BillingAddressesController < ApplicationController
  before_action :set_order
  before_action :set_billing_address

  def edit
    redirect_to @order unless turbo_frame_request?
  end

  def update
    if @billing_address.update(billing_address_params)
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.update("billing_address_modal", ""),
            turbo_stream.replace(
              "billing_address_section",
              partial: "orders/billing_address_section",
              locals: { order: @order, billing_address: @billing_address }
            )
          ]
        end
        format.html { redirect_to @order, notice: "Dane do faktury zostały zaktualizowane" }
      end
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def copy_from_shipping
    shipping_address = @order.shipping_address
    if shipping_address.present?
      @billing_address.update(shipping_address_values(shipping_address))
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "billing_address_section",
            partial: "orders/billing_address_section",
            locals: { order: @order, billing_address: @billing_address }
          )
        end
        format.html { redirect_to @order, notice: "Skopiowano dane z adresu dostawy" }
      end
    else
      redirect_to @order, alert: "Brak adresu dostawy do skopiowania"
    end
  end

  private

  def set_order
    @order = current_account.orders.find_by!(order_number: params[:order_id])
  end

  def set_billing_address
    @billing_address = @order.billing_address || @order.build_billing_address
  end

  def shipping_address_values(shipping_address)
    {
      first_name: shipping_address.first_name,
      last_name: shipping_address.last_name,
      address_line1: shipping_address.address_line1,
      address_line2: shipping_address.address_line2,
      city: shipping_address.city,
      postal_code: shipping_address.postal_code,
      country: shipping_address.country
    }
  end

  def billing_address_params
    params.require(:billing_address).permit(
      :needs_invoice,
      :company_name,
      :nip,
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
