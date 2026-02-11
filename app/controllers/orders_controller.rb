class OrdersController < ApplicationController
  include ActionView::RecordIdentifier
  PER_PAGE_OPTIONS = [ 10, 20, 35, 50, 100, 250 ].freeze
  DEFAULT_PER_PAGE = 10

  def new
    @order = current_account.orders.build
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
        format.html { redirect_to @order, notice: "Zaktualizowano zamówienie" }
      end
    else
      redirect_to @order, alert: "Nie udało się zaktualizować zamówienia"
    end
  end

  def destroy
    @order = current_account.orders.find_by!(order_number: params[:id])
    @order.destroy
    redirect_to orders_path, notice: "Usunięto zamówienie"
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
      flash.now[:notice] = "Kod rabatowy został zastosowany"
    else
      flash.now[:error] = "Kod rabatowy nie jest prawidłowy"
    end

    render turbo_stream: [
      turbo_stream.replace("discount_code_section", partial: "orders/discount_code_section", locals: { order: @order }),
      turbo_stream.update("flash_messages", partial: "layouts/flash_messages")
    ]
  end

  def update_contact_info
    @order = current_account.orders.find_by!(order_number: params[:id])
    if @order.update(contact_info_params)
      flash.now[:notice] = "Dane kontaktowe zostały zaktualizowane"
    else
      flash.now[:error] = "Nie udało się zaktualizować danych kontaktowych"
    end

    render turbo_stream: [
      turbo_stream.replace("contact_info_section", partial: "orders/contact_info_section", locals: { order: @order }),
      turbo_stream.update("flash_messages", partial: "layouts/flash_messages")
    ]
  end

  def edit_payment
    @order = current_account.orders.find_by!(order_number: params[:id])

    redirect_to @order unless turbo_frame_request?
  end

  def update_payment
    @order = current_account.orders.find_by!(order_number: params[:id])
    if @order.update(payment_params)
      flash.now[:notice] = "Płatność została zaktualizowana"
    else
      flash.now[:error] = "Nie udało się zaktualizować płatności"
    end

    render turbo_stream: [
      turbo_stream.replace("payment_section", partial: "orders/payment_section", locals: { order: @order }),
      turbo_stream.update("flash_messages", partial: "layouts/flash_messages")
    ]
  end

  def edit_shipping_payment_methods
    @order = current_account.orders.find_by!(order_number: params[:id])

    redirect_to @order unless turbo_frame_request?
  end

  def update_shipping_payment_methods
    @order = current_account.orders.find_by!(order_number: params[:id])
    if @order.update(shipping_payment_methods_params)
      flash.now[:notice] = "Metody wysyłki i płatności zostały zaktualizowane"
    else
      flash.now[:error] = "Nie udało się zaktualizować metod wysyłki i płatności"
    end

    render turbo_stream: [
      turbo_stream.replace("shipping_payment_methods_section", partial: "orders/shipping_payment_methods_section", locals: { order: @order }),
      turbo_stream.replace("payment_section", partial: "orders/payment_section", locals: { order: @order }),
      turbo_stream.update("flash_messages", partial: "layouts/flash_messages")
    ]
  end

  def update_status
    @order = current_account.orders.find_by!(order_number: params[:id])
    if @order.update(status: params[:order][:status])
      flash.now[:notice] = "Status został zaktualizowany"
    else
      flash.now[:error] = "Nie udało się zaktualizować statusu"
    end

    render turbo_stream: [
      turbo_stream.replace("order_status", partial: "orders/status_dropdown", locals: { order: @order }),
      turbo_stream.update("flash_messages", partial: "layouts/flash_messages")
    ]
  end

  def status_history
    @order = current_account.orders.find_by!(order_number: params[:id])
    @status_history = @order.order_status_histories.chronological

    redirect_to @order unless turbo_frame_request?
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

    count = orders.count
    flash_message = count == 1 ? "zamówienie #{orders.first.order_number}" : "zamówienia"

    case action_type
    when "delete"
      orders.destroy_all

      redirect_to orders_path, notice: "Usunięto #{flash_message}"

    when "update_status"
      new_status = params[:new_status]
      if new_status.present? && Order.statuses.keys.include?(new_status)
        count = orders.update_all(status: Order.statuses[new_status])
        redirect_to orders_path, notice: "Zaktualizowano #{flash_message}"
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

    flash.now[:notice] = "Koszyk aktywowany. Link skopiuj poniżej."
    render turbo_stream: [
      turbo_stream.replace(dom_id(@order, :checkout), partial: "orders/order_checkout", locals: { order: @order }),
      turbo_stream.update("flash_messages", partial: "layouts/flash_messages")
    ]
  end

  def cancel_checkout
    @order = current_account.orders.find_by!(order_number: params[:id])

    checkout = @order.checkout
    checkout.cancel! if checkout.present?

    flash.now[:notice] = "Koszyk anulowany"
    render turbo_stream: [
      turbo_stream.replace(dom_id(@order, :checkout), partial: "orders/order_checkout", locals: { order: @order }),
      turbo_stream.update("flash_messages", partial: "layouts/flash_messages")
    ]
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
end
