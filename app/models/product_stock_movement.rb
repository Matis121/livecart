class ProductStockMovement < ApplicationRecord
  belongs_to :product
  belongs_to :order_item

  MOVEMENT_TYPES = {
    restock: "restock",
    sale: "sale"
  }.freeze

  validates :quantity_change, presence: true, numericality: { only_integer: true }
  validates :quantity_before, presence: true, numericality: { only_integer: true }
  validates :quantity_after, presence: true, numericality: { only_integer: true }
  validates :movement_type, presence: true, inclusion: { in: MOVEMENT_TYPES.values }

  def increase?
    quantity_change > 0
  end

  def decrease?
    quantity_change < 0
  end
end
