class OrdersController < ApplicationController
  PER_PAGE_OPTIONS = [ 10, 20, 35, 50, 100, 250 ].freeze
  DEFAULT_PER_PAGE = 10

  def new
    @order = current_account.orders.build
    @order.order_number = generate_order_number
    @order.status = :draft
    @order.total_amount = 0
    @order.shipping_cost = 0
    @order.currency = "PLN"

    if @order.save
      redirect_to @order, notice: "Utworzono nowe zamówienie"
    else
      redirect_to orders_path, alert: "Nie udało się utworzyć: #{@order.errors.full_messages.join(', ')}"
    end
  end

  def index
    @all_orders = current_account.orders
    @q = @all_orders.ransack(params[:q])
    orders = @q.result.includes(:customer, :order_items).order(created_at: :desc).distinct
    orders = orders.where(status: params[:status]) if params[:status].present?


    @all_orders_count = @all_orders.count

    # Pobierz per_page: najpierw z params, potem z cookies, na końcu default
    per_page = if params[:per_page].present?
      params[:per_page].to_i
    elsif cookies[:orders_per_page].present?
      cookies[:orders_per_page].to_i
    else
      DEFAULT_PER_PAGE
    end

    per_page = DEFAULT_PER_PAGE unless PER_PAGE_OPTIONS.include?(per_page)

    # Zapisz do cookies (na 1 rok)
    cookies[:orders_per_page] = { value: per_page, expires: 1.year.from_now }

    @per_page_options = PER_PAGE_OPTIONS
    @pagy, @orders = pagy(orders, limit: per_page)
  end

  def show
    @order = current_account.orders.find_by(order_number: params[:id])
    @customers = current_account.customers.order(:first_name, :last_name)
    if @order.nil?
      redirect_to orders_path, alert: "Zamówienie nie znalezione"
    end
  end

  def edit_customer
    @order = current_account.orders.find_by!(order_number: params[:id])
    @customers = current_account.customers.order(:first_name, :last_name)

    redirect_to @order unless turbo_frame_request?
  end

  def edit_contact_info
    @order = current_account.orders.find_by!(order_number: params[:id])

    redirect_to @order unless turbo_frame_request?
  end

  def edit_discount_code
    @order = current_account.orders.find_by!(order_number: params[:id])
    redirect_to @order unless turbo_frame_request?
  end

  def update_discount_code
    @order = current_account.orders.find_by!(order_number: params[:id])
    if @order.apply_discount_code(discount_code_params[:discount_code])
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "discount_code_section",
            partial: "orders/discount_code_section",
            locals: { order: @order }
          )
        end
        format.html { redirect_to @order, notice: "Kod rabatowy został zastosowany" }
      end
    else
      render :edit_discount_code, status: :unprocessable_entity
    end
  end

  def update_contact_info
    @order = current_account.orders.find_by!(order_number: params[:id])
    if @order.update(contact_info_params)
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "contact_info_section",
            partial: "orders/contact_info_section",
            locals: { order: @order }
          )
        end
        format.html { redirect_to @order, notice: "Dane kontaktowe zostały zaktualizowane" }
      end
    else
      render :edit_contact_info, status: :unprocessable_entity
    end
  end

  def edit_payment
    @order = current_account.orders.find_by!(order_number: params[:id])

    redirect_to @order unless turbo_frame_request?
  end

  def update_payment
    @order = current_account.orders.find_by!(order_number: params[:id])
    if @order.update(payment_params)
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "payment_section",
            partial: "orders/payment_section",
            locals: { order: @order }
          )
        end
        format.html { redirect_to @order, notice: "Płatność została zaktualizowana" }
      end
    else
      render :edit_payment, status: :unprocessable_entity
    end
  end

  def edit_shipping_payment_methods
    @order = current_account.orders.find_by!(order_number: params[:id])

    redirect_to @order unless turbo_frame_request?
  end

  def update_shipping_payment_methods
    @order = current_account.orders.find_by!(order_number: params[:id])
    if @order.update(shipping_payment_methods_params)
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace(
              "shipping_payment_methods_section",
              partial: "orders/shipping_payment_methods_section",
              locals: { order: @order }
            ),
            turbo_stream.replace(
              "payment_section",
              partial: "orders/payment_section",
              locals: { order: @order }
            )
          ]
        end
        format.html { redirect_to @order, notice: "Metody wysyłki i płatności zostały zaktualizowane" }
      end
    else
      render :edit_shipping_payment_methods, status: :unprocessable_entity
    end
  end

  def update_status
    @order = current_account.orders.find_by!(order_number: params[:id])
    if @order.update(status: params[:order][:status])
        render turbo_stream: turbo_stream.replace(
          "order_status",
          partial: "orders/status_dropdown",
          locals: { order: @order }
        )
    end
  end

  def status_history
    @order = current_account.orders.find_by!(order_number: params[:id])
    @status_history = @order.order_status_histories.chronological

    redirect_to @order unless turbo_frame_request?
  end

  def update
    @order = current_account.orders.find_by!(order_number: params[:id])
    if @order.update(order_params)
      respond_to do |format|
        format.turbo_stream do
          # Sprawdź czy aktualizowano status czy klienta
          if params[:order][:status].present?
            render turbo_stream: turbo_stream.replace(
              "order_status",
              partial: "orders/status_dropdown",
              locals: { order: @order }
            )
          else
            render turbo_stream: turbo_stream.replace(
              "customer_section",
              partial: "orders/customer_section",
              locals: { order: @order }
            )
          end
        end
        format.html { redirect_to @order, notice: "Zamówienie zostało zaktualizowane" }
      end
    else
      redirect_to @order, alert: "Nie udało się zaktualizować zamówienia"
    end
  end

  def destroy
    @order = current_account.orders.find_by!(order_number: params[:id])
    @order.destroy
    redirect_to orders_path, notice: "Zamówienie zostało usunięte"
  end

  def bulk_action
    order_ids = params[:order_ids] || []
    action_type = params[:action_type]

    if order_ids.empty?
      redirect_to orders_path, alert: "Nie wybrano żadnych zamówień"
      return
    end

    # Znajdź zamówienia należące do current_account
    orders = current_account.orders.where(order_number: order_ids)

    case action_type
    when "delete"
      count = orders.count
      orders.destroy_all
      redirect_to orders_path, notice: "Usunięto #{count} zamówień"

    when "update_status"
      new_status = params[:new_status]
      if new_status.present? && Order.statuses.keys.include?(new_status)
        count = orders.update_all(status: Order.statuses[new_status])
        redirect_to orders_path, notice: "Zaktualizowano status #{count} zamówień"
      else
        redirect_to orders_path, alert: "Nieprawidłowy status"
      end

    else
      redirect_to orders_path, alert: "Nieznana akcja"
    end
  end

  def activate_checkout
    @order = current_account.orders.find_by!(order_number: params[:id])

    checkout = @order.checkout || @order.create_checkout!
    checkout.activate!

    redirect_to @order, notice: "Koszyk aktywowany. Link skopiuj poniżej."
  rescue => e
    redirect_to @order, alert: "Błąd: #{e.message}"
  end

  def cancel_checkout
    @order = current_account.orders.find_by!(order_number: params[:id])

    checkout = @order.checkout
    checkout.cancel! if checkout.present?

    redirect_to @order, notice: "Koszyk anulowany"
  end

  private

  def discount_code_params
    params.require(:order).permit(:discount_code)
  end

  def order_params
    params.require(:order).permit(:customer_id, :status)
  end

  def contact_info_params
    params.require(:order).permit(:email, :phone)
  end

  def payment_params
    params.require(:order).permit(:paid_amount)
  end

  def shipping_payment_methods_params
    params.require(:order).permit(:payment_method, :shipping_method, :shipping_cost)
  end

  def generate_order_number
    10.times do
      day_of_year = Time.now.strftime("%j")
      random_part = (10000..99999).to_a.sample  # Losuj z całego zakresu
      number = "#{day_of_year}#{random_part}"

      return number unless current_account.orders.exists?(order_number: number)
    end

    raise "Nie udało się wygenerować unikalnego numeru"
  end
end
