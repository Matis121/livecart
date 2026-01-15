# app/models/order_status_history.rb
class OrderStatusHistory < ApplicationRecord
  belongs_to :order

  enum :status, Order.statuses, prefix: :to, suffix: false

  validates :status, presence: true
  validates :order, presence: true

  scope :chronological, -> { order(created_at: :asc) }


  def status_name
    Order::STATUS_NAMES[status.to_sym] || status
  end
end
