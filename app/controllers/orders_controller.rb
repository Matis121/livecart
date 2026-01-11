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
    @order = current_account.orders.find_by!(order_number: params[:id])
    if @order.nil?
      redirect_to orders_path, alert: "Zamówienie nie znalezione"
    end
  end

  private

  def order_params
    params.require(:order).permit(:customer_id, :status)
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
