class ProductStock < ApplicationRecord
  belongs_to :product

  before_validation :set_defaults, on: :create

  validates :quantity, presence: true, numericality: { only_integer: true }
  validates :last_synced_at, presence: true
  validates :sync_enabled, inclusion: { in: [ true, false ] }

  # Ręczna korekta stanu magazynowego z UI
  def adjust_quantity!(new_qty)
    new_qty = new_qty.to_i

    transaction do
      # Zablokuj wiersz i odśwież dane z bazy (zapobiega race condition)
      lock!
      reload

      return if new_qty == quantity

      old_qty = quantity
      change = new_qty - old_qty

      update!(quantity: new_qty)

      product.product_stock_movements.create!(
        order_item: nil,
        quantity_change: change,
        quantity_before: old_qty,
        quantity_after: new_qty,
        movement_type: :manual_update
      )
    end
  end

  # Zmniejszenie stanu przez zamówienie
  def decrease_for_order!(amount, order_item:, movement_type: "sale")
    transaction do
      # Zablokuj wiersz i odśwież dane z bazy (zapobiega race condition)
      lock!
      reload

      old_qty = quantity
      new_qty = quantity - amount

      update!(quantity: new_qty)

      product.product_stock_movements.create!(
        order_item: order_item,
        quantity_change: -amount,
        quantity_before: old_qty,
        quantity_after: new_qty,
        movement_type: movement_type
      )
    end
  end

  # Zwiększenie stanu (przywrócenie/korekta)
  def increase_for_order!(amount, order_item:, movement_type: "restock")
    transaction do
      # Zablokuj wiersz i odśwież dane z bazy (zapobiega race condition)
      lock!
      reload

      old_qty = quantity
      new_qty = quantity + amount

      update!(quantity: new_qty)

      product.product_stock_movements.create!(
        order_item: order_item,
        quantity_change: amount,
        quantity_before: old_qty,
        quantity_after: new_qty,
        movement_type: movement_type
      )
    end
  end

  # Ransack configuration
  def self.ransackable_attributes(auth_object = nil)
    [ "quantity" ]
  end

  private

  def set_defaults
    self.last_synced_at ||= Time.current
    self.sync_enabled = false if sync_enabled.nil?
  end
end
