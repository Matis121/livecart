class OrderItem < ApplicationRecord
  belongs_to :order
  belongs_to :product, optional: true
  has_one :product_reservation, dependent: :destroy
  has_many :product_stock_movements, dependent: :nullify

  validates :name, presence: true
  validates :unit_price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :quantity, presence: true, numericality: { greater_than: 0, only_integer: true }
  validates :total_price, presence: true, numericality: { greater_than_or_equal_to: 0 }

  # Automatyczne obliczanie total_price przed walidacją
  before_validation :calculate_total_price

  # Przelicz total zamówienia po zapisie lub usunięciu
  after_save :recalculate_order_total
  after_destroy :recalculate_order_total

  # Rezerwacje (TYLKO dla draft orders)
  after_create :create_reservation, if: :should_reserve?
  after_update :update_reservation_quantity, if: :quantity_changed_and_draft?

  # Ransack - dozwolone atrybuty do wyszukiwania
  def self.ransackable_attributes(auth_object = nil)
    %w[name unit_price quantity total_price]
  end

  private

  def calculate_total_price
    self.total_price = unit_price.to_f * quantity.to_i if unit_price.present? && quantity.present?
  end

  def recalculate_order_total
    return unless order

    items_total = order.order_items.reload.sum(:total_price)
    order.update_column(:total_amount, items_total + (order.shipping_cost || 0))
  end

  # === WARUNKI ===

  def should_reserve?
    product.present? && order.draft_status?
  end

  def quantity_changed_and_draft?
    saved_change_to_quantity? && product.present? && order.draft_status?
  end


  # === REZERWACJE ===

  def create_reservation
    ProductReservation.create!(
      product: product,
      order: order,
      order_item: self,
      quantity: quantity,
      status: "pending"
    )
  rescue StandardError => e
    errors.add(:base, "Nie można zarezerwować: #{e.message}")
    raise ActiveRecord::Rollback
  end

  def update_reservation_quantity
    return unless product_reservation&.pending?

    product_reservation.update!(quantity: quantity)
  rescue StandardError => e
    errors.add(:base, "Nie można zaktualizować rezerwacji: #{e.message}")
    raise ActiveRecord::Rollback
  end

  def cancel_reservation_if_exists
    product_reservation&.cancel! if product_reservation&.pending?
  end
end
