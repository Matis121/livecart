class OrderItem < ApplicationRecord
  belongs_to :order
  belongs_to :product, optional: true

  validates :name, presence: true
  validates :unit_price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :quantity, presence: true, numericality: { greater_than: 0, only_integer: true }
  validates :total_price, presence: true, numericality: { greater_than_or_equal_to: 0 }

  # Automatyczne obliczanie total_price przed walidacją
  before_validation :calculate_total_price

  # Przelicz total zamówienia po zapisie lub usunięciu
  after_save :recalculate_order_total
  after_destroy :recalculate_order_total

  private

  def calculate_total_price
    self.total_price = unit_price.to_f * quantity.to_i if unit_price.present? && quantity.present?
  end

  def recalculate_order_total
    return unless order

    items_total = order.order_items.reload.sum(:total_price)
    order.update_column(:total_amount, items_total + (order.shipping_cost || 0))
  end
end
