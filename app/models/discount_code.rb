class DiscountCode < ApplicationRecord
  belongs_to :account
  has_many :orders, dependent: :nullify

  validates :code, presence: true, uniqueness: true
  validates :value, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :kind, presence: true, inclusion: { in: [ "percentage", "fixed" ] }

  enum :kind, {
    percentage: 0,
    fixed: 1
  }

  def applicable_for?(subtotal)
    return false unless active?
    return false if valid_from.present? && valid_from > Time.current
    return false if valid_until.present? && valid_until < Time.current
    return false if usage_limit.present? && used_count >= usage_limit
    return false if minimum_order_amount.present? && subtotal < minimum_order_amount
    true
  end

  def discount_amount(subtotal)
    return 0 unless applicable_for?(subtotal)
    amount = percentage? ? (subtotal * value / 100) : [ value, subtotal ].min
    amount.round(2)
  end

  def discount_for_order(order)
    subtotal = order.order_items.sum(:total_price)
    return 0 unless applicable_for?(subtotal)

    amount = discount_amount(subtotal)  # rabat od produktów
    amount += order.shipping_cost if free_shipping?
    amount.round(2)
  end
end
