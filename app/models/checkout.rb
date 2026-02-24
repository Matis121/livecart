class Checkout < ApplicationRecord
  belongs_to :order

  delegate :shipping_address, :billing_address, :order_number, :total_amount, :currency, :order_items, :customer, :payment_method, to: :order
  delegate :order_number, :total_amount, :currency, :order_items, :customer, :payment_method, :delivery_method, to: :order

  validates :token, presence: true, uniqueness: true
  validates :activation_hours, numericality: { greater_than: 0 }

  before_validation :generate_token, on: :create

  def activate!(hours = nil)
    hours ||= activation_hours || 24
    update!(
      active: true,
      expires_at: hours.hours.from_now,
    )
  end

  def expired?
    expires_at.present? && expires_at < Time.current
  end

  def completed?
    completed_at.present?
  end

  def available?
    active && !expired? && !completed?
  end

  def open_package_pending?
    open_package && completed_at.blank?
  end

  def open_package!
    update!(
      open_package: true,
      open_package_at: Time.current
    )
  end

  def close_package!
    complete!
  end

  def complete!
    update!(
      active: false,
      completed_at: Time.current
    )
  end

  def cancel!
    update!(
      active: false,
    )
  end

  def public_url
    # Dla development
    "http://localhost:3000/shops/#{order.account.slug}/checkouts/#{token}"
  end

  private

  def generate_token
    return if token.present?

    self.token = loop do
      token = SecureRandom.urlsafe_base64(16)
      break token unless self.class.exists?(token: token)
    end
  end
end
