class ProductStockMovement < ApplicationRecord
  belongs_to :product
  belongs_to :order_item, optional: true

  enum :movement_type, {
    restock: 0,
    sale: 1,
    adjustment: 2,
    deleted: 3,
    manual_update: 4
  }

  MOVEMENT_TYPES = {
    restock: "Przyjęcie",
    sale: "Sprzedaż",
    adjustment: "Korekta stanu",
    deleted: "Usunięcie",
    manual_update: "Aktualizacja ręczna"
  }.freeze


  validates :quantity_change, presence: true, numericality: { only_integer: true }
  validates :quantity_before, presence: true, numericality: { only_integer: true }
  validates :quantity_after, presence: true, numericality: { only_integer: true }
  validates :movement_type, presence: true

  def increase?
    quantity_change > 0
  end

  def decrease?
    quantity_change < 0
  end

  def movement_type_name
    MOVEMENT_TYPES[movement_type.to_sym] || movement_type
  end
end
