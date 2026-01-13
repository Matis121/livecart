class ProductReservationsController < ApplicationController
  def index
    @product_reservations = ProductReservation
      .joins(:product)
      .where(products: { account_id: current_account.id })
      .pending
      .includes(:product, :order, :order_item)
      .order(created_at: :desc)
  end
end
