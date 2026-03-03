class DashboardController < ApplicationController
  REVENUE_STATUSES = %w[paid in_fulfillment shipped delivered].freeze

  def index
    beginning_of_month = Time.current.beginning_of_month
    beginning_of_day   = Time.current.beginning_of_day

    @orders_count_today = current_account.orders.where(created_at: beginning_of_day..).count
    @orders_count_month = current_account.orders.where(created_at: beginning_of_month..).count
    @orders_count_total = current_account.orders.count

    @revenue_this_month = current_account.orders
      .where(created_at: beginning_of_month..)
      .where(status: REVENUE_STATUSES)
      .sum(:total_amount)

    @customers_count          = current_account.customers.count
    @new_customers_this_month = current_account.customers.where(created_at: beginning_of_month..).count

    @products_count = current_account.products.count

    @recent_orders = current_account.orders
      .includes(:customer)
      .order(created_at: :desc)
      .limit(8)

    @orders_by_status = current_account.orders
      .where(created_at: beginning_of_month..)
      .group(:status)
      .count
  end
end
