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
  validates :currency, presence: true, inclusion: { in: [ "PLN", "EUR", "USD" ] }

  after_initialize :build_blank_addresses

  def to_param
    order_number
  end

  private

  def build_blank_addresses
    return unless new_record?

    self.shipping_address ||= build_shipping_address
    self.billing_address ||= build_billing_address
  end
end
