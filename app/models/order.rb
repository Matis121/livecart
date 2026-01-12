class Order < ApplicationRecord
  belongs_to :account
  belongs_to :customer, optional: true
  has_many :order_items, dependent: :destroy
  has_one :shipping_address, dependent: :destroy
  has_one :billing_address, dependent: :destroy

  validates :order_number, presence: true, uniqueness: true
  validates :order_token, presence: true, uniqueness: true
  validates :status, presence: true, inclusion: { in: [  "draft", "sent", "processing", "completed", "paid", "cancelled" ] }
  validates :total_amount, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :shipping_cost, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :paid_amount, numericality: { greater_than_or_equal_to: 0 }
  validates :currency, presence: true, inclusion: { in: [ "PLN", "EUR", "USD" ] }
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP, allow_blank: true }
validates :phone, format: { with: /\A[+]?[\d\s\-()]+\z/, allow_blank: true }

  after_initialize :build_blank_addresses
  after_update :recalculate_total_if_shipping_changed, if: :saved_change_to_shipping_cost?

  def to_param
    order_number
  end

  def paid?
    return false if total_amount.zero?
    (paid_amount || 0) == total_amount
  end

  def payment_badge_class
    return "badge-neutral" if total_amount.zero?
    paid? ? "badge-success" : "badge-error"
  end

  private

  def build_blank_addresses
    return unless new_record?

    self.shipping_address ||= build_shipping_address
    self.billing_address ||= build_billing_address
  end

  def recalculate_total_if_shipping_changed
    items_total = order_items.sum(:total_price)
    update_column(:total_amount, items_total + shipping_cost)
  end
end
