class OrderItem < ApplicationRecord
  belongs_to :order
  belongs_to :product, optional: true
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


  # Zarządzanie stanem magazynowym
  after_create :decrease_stock
  after_update :adjust_stock
  before_destroy :restore_stock

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


  # === ZARZĄDZANIE STANEM MAGAZYNOWYM ===

  def decrease_stock
    product.product_stock.decrease_for_order!(quantity, order_item: self, movement_type: "sale")
  end

  def adjust_stock
    return unless saved_change_to_quantity?
    old_quantity, new_quantity = saved_change_to_quantity
    difference = new_quantity - old_quantity

    if difference > 0
      product.product_stock.decrease_for_order!(difference, order_item: self, movement_type: "adjustment")
    elsif difference < 0
      product.product_stock.increase_for_order!(difference.abs, order_item: self, movement_type: "adjustment")
    end
  end

  def restore_stock
    product.product_stock.increase_for_order!(quantity, order_item: nil, movement_type: "deleted")
  end
end
