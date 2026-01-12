class OrderItemsController < ApplicationController
  before_action :set_order
  before_action :set_order_item, only: [ :edit, :update, :destroy ]
  before_action :load_products, only: [ :new, :edit, :create, :update ]

  def new
    @order_item = @order.order_items.build
  end

  def quick_add
    cart_items = JSON.parse(params[:cart_items] || "[]")
    added_items = []
    errors = []

    cart_items.each do |item_data|
      product = current_account.products.find_by(id: item_data["id"])
      next unless product

      order_item = @order.order_items.build(
        product_id: product.id,
        name: item_data["name"],
        sku: item_data["sku"] || "",
        ean: item_data["ean"] || "",
        unit_price: item_data["unit_price"].to_f,
        quantity: item_data["quantity"].to_i
      )

      if order_item.save
        added_items << order_item
      else
        errors << "#{product.name}: #{order_item.errors.full_messages.join(', ')}"
      end
    end

    if added_items.any?
      render_success_response("Dodano #{added_items.count} produktów do zamówienia", include_form_clear: true)
    else
      render_error_response(errors.any? ? errors : [ "Nie udało się dodać produktów" ])
    end
  rescue JSON::ParserError
    redirect_to @order, alert: "Nieprawidłowe dane"
  end

  def create
    @order_item = @order.order_items.build(order_item_params)

    if @order_item.save
      render_success_response("Produkt został dodany do zamówienia", include_form_clear: true)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @order_item.update(order_item_params)
      render_success_response("Produkt został zaktualizowany")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @order_item.destroy
    @order.reload
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.replace("order_items", partial: "order_items/list", locals: { order: @order }),
          turbo_stream.replace("payment_section", partial: "orders/payment_section", locals: { order: @order })
        ]
      end
      format.html { redirect_to @order, notice: "Produkt został usunięty" }
    end
  end

  private

  def set_order
    @order = current_account.orders.find_by!(order_number: params[:order_id])
  end

  def set_order_item
    @order_item = @order.order_items.find(params[:id])
  end

  def load_products
    @products = current_account.products.order(:name)
  end

  def order_item_params
    params.require(:order_item).permit(:product_id, :name, :ean, :sku, :unit_price, :quantity)
  end

  def render_success_response(notice, include_form_clear: false)
    @order.reload
    respond_to do |format|
      format.turbo_stream do
        streams = [
          turbo_stream.replace("order_items", partial: "order_items/list", locals: { order: @order }),
          turbo_stream.replace("payment_section", partial: "orders/payment_section", locals: { order: @order })
        ]
        streams << turbo_stream.update("new_order_item", "") if include_form_clear
        render turbo_stream: streams
      end
      format.html { redirect_to @order, notice: notice }
    end
  end

  def render_error_response(errors)
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.update("new_order_item",
          partial: "order_items/error",
          locals: { order: @order, errors: errors })
      end
      format.html { redirect_to @order, alert: errors.first }
    end
  end
end
