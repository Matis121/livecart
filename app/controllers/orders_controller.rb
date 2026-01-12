class OrdersController < ApplicationController
  def new
    @order = current_account.orders.build
    @order.order_number = generate_order_number
    @order.order_token = SecureRandom.urlsafe_base64(16)
    @order.status = "draft"
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
    @orders = current_account.orders.order(created_at: :desc)
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
  end

  def edit_contact_info
    @order = current_account.orders.find_by!(order_number: params[:id])
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

  def update
    @order = current_account.orders.find_by!(order_number: params[:id])
    if @order.update(order_params)
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "customer_section",
            partial: "orders/customer_section",
            locals: { order: @order }
          )
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

  private

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
