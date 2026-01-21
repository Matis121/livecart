class ProductStock < ApplicationRecord
  belongs_to :product

  before_validation :set_defaults, on: :create

  validates :quantity, presence: true, numericality: { only_integer: true }
  validates :last_synced_at, presence: true
  validates :sync_enabled, inclusion: { in: [ true, false ] }

  def reserved_quantity
    product.product_reservations.pending.sum(:quantity)
  end

  def available_quantity
    quantity - reserved_quantity
  end

  def in_stock?
    available_quantity > 0
  end

  def shortage
    available_quantity < 0 ? available_quantity.abs : 0
  end

  private

  def set_defaults
    self.last_synced_at ||= Time.current
    self.sync_enabled = false if sync_enabled.nil?
  end

  public

  # TYLKO TA METODA - wywoływana automatycznie przez Order callback
  def decrease_for_order!(amount, order_item:)
    transaction do
      old_qty = quantity
      new_qty = quantity - amount

      update!(quantity: new_qty)

      # Historia
      product.product_stock_movements.create!(
        order_item: order_item,
        quantity_change: -amount,
        quantity_before: old_qty,
        quantity_after: new_qty,
        movement_type: "sale"
      )
    end
  end

  # Ransack configuration
  def self.ransackable_attributes(auth_object = nil)
    [ "quantity", "available_quantity", "reserved_quantity" ]
  end
end
