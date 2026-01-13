class ProductReservation < ApplicationRecord
  belongs_to :product
  belongs_to :order
  belongs_to :order_item

  delegate :customer, to: :order, allow_nil: true

  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validates :status, presence: true, inclusion: { in: [ "pending", "completed", "cancelled" ] }

    # Scopes
    scope :pending, -> { where(status: "pending") }
    scope :completed, -> { where(status: "completed") }
    scope :cancelled, -> { where(status: "cancelled") }
    scope :for_product, ->(product) { where(product: product) }
    scope :for_order, ->(order) { where(order: order) }

  def pending?
    status == "pending"
  end

  def completed?
    status == "completed"
  end

  def cancelled?
    status == "cancelled"
  end

  def complete!
    update!(status: "completed")
  end

  def cancel!
    update!(status: "cancelled")
  end
end
