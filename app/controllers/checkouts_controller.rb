class CheckoutsController < ApplicationController
  skip_before_action :authenticate_user!, only: [ :show, :update, :close_package, :apply_discount, :not_found ]

  before_action :find_shop, except: [ :not_found ]
  before_action :find_checkout, except: [ :not_found ]
  before_action :set_order, except: [ :not_found ]
  before_action :validate_shop_ownership, except: [ :not_found ]
  before_action :validate_availability, except: [ :not_found ]
  before_action :set_shipping_methods, except: [ :not_found ]
  before_action :set_payment_methods, except: [ :not_found ]

  def show
    set_checkout_view_data
    @open_package_enabled = @account.open_package_enabled?

    if params[:payu_return].present?
      # Klient wrócił z PayU
      if @order.payment_processing?
        # IPN jeszcze nie dotarł — pokaż stronę oczekiwania
        return render :payu_pending
      end
      # IPN już zadziałał (order nie jest payment_processing) — pokaż sukces
      return
    end

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
    # Jeśli open_package_pending? — widok sam renderuje stronę zamknięcia paczki
  end

  def update
    if params[:commit_type] == "open_package" && @order.account.open_package_enabled?
      update_open_package
    else
      update_ship_now
    end
  end

  def close_package
    payment_method_name = params[:order][:payment_method]
    payment_method_record = @order.account.payment_methods.find_by(name: payment_method_name)

    ActiveRecord::Base.transaction do
      shipping_method = @order.account.shipping_methods.find(params[:order][:shipping_method_id])
      @order.update!(shipping_method: shipping_method.name, shipping_cost: shipping_method.price)

      if shipping_method.is_pickup_point?
        attrs = pickup_point_params
        if @order.pickup_point.present?
          @order.pickup_point.update!(attrs)
        else
          @order.create_pickup_point!(attrs)
        end
      end

      @order.update!(
        payment_method: payment_method_name,
        cash_on_delivery: payment_method_record&.cash_on_delivery? || false
      )

      if payu_payment?(payment_method_record)
        @order.update!(status: :payment_processing)
      else
        @order.update!(status: :in_fulfillment)
        @checkout.close_package!
      end
    end

    if payu_payment?(payment_method_record)
      redirect_to_payu(payment_method_record.integration)
    else
      session[:show_success_for_checkout] = @checkout.id
      redirect_to checkout_path(@shop.slug, @checkout.token)
    end
  rescue => e
    set_checkout_view_data
    @order.errors.add(:base, e.message)
    render :show, status: :unprocessable_entity
  end

  def apply_discount
    code = params[:discount_code].to_s.strip
    success = @order.apply_discount_code(code)
    discount_error = success ? nil : @order.errors.full_messages.to_sentence

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "order_summary",
          partial: "checkouts/order_summary",
          locals: { order: @order, discount_error: discount_error }
        )
      end
      format.html do
        if success
          redirect_to checkout_path(@shop.slug, @checkout.token), notice: code.blank? ? "Kod rabatowy usunięty." : "Kod rabatowy zastosowany!"
        else
          redirect_to checkout_path(@shop.slug, @checkout.token), alert: discount_error
        end
      end
    end
  end

  def not_found
    # Renderuje widok not_found.html.erb
  end

  private

  def set_shipping_methods
    @shipping_methods = @order.account.shipping_methods.active.order(:position)
  end

  def set_payment_methods
    @payment_methods = @order.account.payment_methods.active.order(:position)
  end

  def set_order
    @order = @checkout.order
  end

  def find_shop
    @shop = Account.find_by!(slug: params[:shop_slug])
  rescue ActiveRecord::RecordNotFound
    redirect_to not_found_checkouts_path
  end

  def find_checkout
    @checkout = Checkout.find_by!(token: params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to not_found_checkouts_path
  end

  def validate_shop_ownership
    unless @order.account_id == @shop.id
      redirect_to not_found_checkouts_path
    end
  end

  def validate_availability
    # Jeśli checkout NIE jest zakończony, sprawdź czy jest dostępny
    unless @checkout.completed?
      unless @checkout.available?
        redirect_to not_found_checkouts_path
      end
    end
  end

  # Ścieżka "Wyślij teraz" — pełny flow z płatnością
  def update_ship_now
    if update_order_data(include_payment: true)
      payment_method_record = @order.account.payment_methods.find_by(name: @order.payment_method)

      if payu_payment?(payment_method_record)
        @order.update!(status: :payment_processing)
        redirect_to_payu(payment_method_record.integration)
      else
        @order.update!(status: :in_fulfillment)
        @checkout.complete!
        session[:show_success_for_checkout] = @checkout.id
        redirect_to checkout_path(@shop.slug, @checkout.token)
      end
    else
      render :show, status: :unprocessable_entity
    end
  end

  # Ścieżka "Otwarta paczka" — bez płatności, ustawia status open_package na Order
  def update_open_package
    if update_order_data(include_payment: false)
      @checkout.open_package!
      @order.update!(status: :open_package)
      session[:show_success_for_checkout] = @checkout.id
      redirect_to checkout_path(@shop.slug, @checkout.token)
    else
      render :show, status: :unprocessable_entity
    end
  end

  def update_order_data(include_payment: true)
    ActiveRecord::Base.transaction do
      # Aktualizuj dane kontaktowe
      @order.update!(contact_params)

      # Aktualizuj adres dostawy
      @order.shipping_address.update!(shipping_address_params)

      # Aktualizuj adres do faktury (jeśli potrzebny)
      if billing_address_params[:needs_invoice] == "1"
        @order.billing_address.update!(billing_address_params)
      end

      # Aktualizuj metodę dostawy i płatności (tylko dla "wyślij teraz")
      if include_payment
        shipping_method = @order.account.shipping_methods.find(params[:order][:shipping_method_id])
        @order.update!(shipping_method: shipping_method.name, shipping_cost: shipping_method.price)

        if shipping_method.is_pickup_point?
          attrs = pickup_point_params
          if @order.pickup_point.present?
            @order.pickup_point.update!(attrs)
          else
            @order.create_pickup_point!(attrs)
          end
        end

        payment_method_name = params[:order][:payment_method]
        payment_method_record = @order.account.payment_methods.find_by(name: payment_method_name)
        @order.update!(
          payment_method: payment_method_name,
          cash_on_delivery: payment_method_record&.cash_on_delivery? || false
        )
      end

      true
    end
  rescue => e
    @order.errors.add(:base, e.message)
    false
  end

  def payu_payment?(method_record)
    method_record&.gateway? && method_record.integration&.payu?
  end

  def set_checkout_view_data
    @account = @order.account
    @account_logo = @account.logo.attached? ? @account.logo : nil
    @account_name = @account.checkout_settings["shop_name"]
    @inpost_widget_token = ENV["INPOST_WIDGET_TOKEN"]
    @orlen_widget_token = ENV["ORLEN_WIDGET_TOKEN"]
  end

  def redirect_to_payu(integration)
    result = Integrations::Payu::OrderCreator.new(integration: integration, order: @order)
      .call(
        notify_url: payments_payu_notify_url,
        continue_url: checkout_url(@shop.slug, @checkout.token, payu_return: 1),
        customer_ip: request.remote_ip
      )

    if result.success?
      redirect_to result.data[:redirect_uri], allow_other_host: true
    else
      set_checkout_view_data
      @order.errors.add(:base, "Błąd płatności PayU: #{result.errors.join(', ')}")
      render :show, status: :unprocessable_entity
    end
  end

  def pickup_point_params
    params.require(:order).require(:pickup_point_attributes)
          .permit(:point_id, :name, :address_line1, :postal_code, :city)
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
