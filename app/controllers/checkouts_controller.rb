class CheckoutsController < ApplicationController
  skip_before_action :authenticate_user!, only: [ :show, :update, :not_found ]

  before_action :find_checkout, except: [ :not_found ]
  before_action :set_order, except: [ :not_found ]
  before_action :validate_availability, except: [ :not_found ]
  before_action :set_shipping_methods, except: [ :not_found ]

  def show
    @account = current_account
    @account_logo = @account.logo.attached? ? @account.logo : nil
    @account_name = @account.checkout_settings["name"]

    # Jeśli checkout jest zakończony, sprawdź czy to pierwsza wizyta po zakończeniu
    if @checkout.completed?
      if session[:show_success_for_checkout] == @checkout.id
        # Pokaż stronę sukcesu i wyczyść flagę
        session.delete(:show_success_for_checkout)
      else
        # Nie ma flagi - to ponowna wizyta, przekieruj
        redirect_to not_found_checkouts_path
      end
    end
  end

  def update
    if update_order_data
      @checkout.complete!
      # Ustaw flagę, że można pokazać stronę sukcesu
      session[:show_success_for_checkout] = @checkout.id
      redirect_to checkout_path(@checkout.token)
    else
      render :show, status: :unprocessable_entity
    end
  end

  def not_found
    # Renderuje widok not_found.html.erb
  end

  private

  def set_shipping_methods
    @shipping_methods = @order.account.shipping_methods.active.order(:position)
  end

  def set_order
    @order = @checkout.order
  end

  def find_checkout
    @checkout = Checkout.find_by!(token: params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to not_found_checkouts_path
  end

  def validate_availability
    # Jeśli checkout NIE jest zakończony, sprawdź czy jest dostępny
    unless @checkout.completed?
      unless @checkout.available?
        redirect_to not_found_checkouts_path
      end
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
      @order.update!(payment_method: params[:order][:payment_method])

      # Aktualizuj koszt wysyłki
      shipping_method = @order.account.shipping_methods.find(params[:order][:shipping_method_id])
      @order.update!(shipping_method: shipping_method.name, shipping_cost: shipping_method.price)


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
end
