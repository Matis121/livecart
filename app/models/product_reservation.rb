class ProductReservation < ApplicationRecord
  belongs_to :product
  belongs_to :order
  belongs_to :order_item

  enum :status, {
    pending: 0,
    completed: 1,
    cancelled: 2
  }

  STATUS_NAMES = {
    pending: "Oczekująca",
    completed: "Zrealizowana",
    cancelled: "Anulowana"
  }.freeze

  delegate :customer, to: :order, allow_nil: true

  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validates :status, presence: true

    # Scopes
    scope :pending, -> { where(status: "pending") }
    scope :completed, -> { where(status: "completed") }
    scope :cancelled, -> { where(status: "cancelled") }
    scope :for_product, ->(product) { where(product: product) }
    scope :for_order, ->(order) { where(order: order) }

  def status_name
    STATUS_NAMES[status.to_sym] || status
  end

  def status_badge_class
    case status
    when "pending"
      "warning"
    when "completed"
      "success"
    when "cancelled"
      "error"
    end
  end
end
