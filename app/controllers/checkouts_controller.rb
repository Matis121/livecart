class CheckoutsController < ApplicationController
  skip_before_action :authenticate_user!, only: [ :show, :update ]

  before_action :find_checkout
  before_action :set_order
  before_action :validate_availability

  def show
  end

  def update
    if update_order_data
      @checkout.complete!
      redirect_to checkout_path(@checkout.token)
    else
      render :show, status: :unprocessable_entity
    end
  end

  private

  def set_order
    @order = @checkout.order
  end

  def find_checkout
    @checkout = Checkout.find_by!(token: params[:id])
  rescue ActiveRecord::RecordNotFound
    render plain: "Link do realizacji zamówienia jest nieprawidłowy lub wygasł", status: :not_found
  end

  def validate_availability
    return if @checkout.completed?

    unless @checkout.available?
      redirect_to root_path, alert: "Link do realizacji zamówienia jest nieprawidłowy lub wygasł"
    end
  end

  def update_order_data
    ActiveRecord::Base.transaction do
      # Aktualizuj dane kontaktowe
      @order.update!(contact_params)

      # Aktualizuj adres dostawy
      @order.shipping_address.update!(shipping_address_params)

      # Aktualizuj adres do faktury (jeśli potrzebny)
      if billing_address_params[:needs_invoice] == "1"
        @order.billing_address.update!(billing_address_params)
      end

      # Aktualizuj metodę płatności i dostawy
      @order.update!(payment_shipping_params)

      # Zmień status zamówienia
      @order.update!(status: :payment_processing)

      true
    end
  rescue => e
    @order.errors.add(:base, e.message)
    false
  end

  def contact_params
    params.require(:order).permit(:email, :phone)
  end

  def shipping_address_params
    params.require(:order).require(:shipping_address_attributes).permit(
      :first_name, :last_name, :address_line1, :address_line2,
      :city, :postal_code, :country
    )
  end

  def billing_address_params
    params.require(:order).require(:billing_address_attributes).permit(
      :needs_invoice, :company_name, :nip, :first_name, :last_name,
      :address_line1, :address_line2, :city, :postal_code, :country
    )
  end

  def payment_shipping_params
    params.require(:order).permit(:payment_method, :shipping_method)
  end
end
