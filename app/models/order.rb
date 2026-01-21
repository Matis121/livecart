class Order < ApplicationRecord
  belongs_to :account
  belongs_to :customer, optional: true
  has_many :order_items, dependent: :destroy
  has_one :shipping_address, dependent: :destroy
  has_one :billing_address, dependent: :destroy
  has_many :product_reservations, dependent: :destroy
  has_many :order_status_histories, dependent: :destroy
  has_one :checkout, dependent: :destroy

  accepts_nested_attributes_for :shipping_address
  accepts_nested_attributes_for :billing_address

  enum :status, {
    draft: 0,
    offer_sent: 1,
    payment_processing: 2,
    paid: 3,
    in_fulfillment: 4,
    shipped: 5,
    delivered: 6,
    cancelled: 7,
    returned: 8
  }, suffix: :status

  STATUS_NAMES = {
    draft: "Szkic",
    offer_sent: "Oferta wysłana",
    payment_processing: "Płatność w trakcie",
    paid: "Opłacone",
    in_fulfillment: "W realizacji",
    shipped: "Wysłane",
    delivered: "Dostarczone",
    cancelled: "Anulowane",
    returned: "Zwrócone"
  }.freeze

  validates :order_number, presence: true, uniqueness: true
  validates :status, presence: true
  validates :total_amount, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :shipping_cost, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :paid_amount, numericality: { greater_than_or_equal_to: 0 }
  validates :currency, presence: true, inclusion: { in: [ "PLN", "EUR", "USD" ] }
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP, allow_blank: true }
  validates :phone, format: { with: /\A[+]?[\d\s\-()]+\z/, allow_blank: true }

  # Adresy
  after_initialize :build_blank_addresses
  after_update :recalculate_total_if_shipping_changed, if: :saved_change_to_shipping_cost?


  # Gospodarka magazynowa
  after_update :finalize_order_stock, if: :paid_status?
  after_update :cancel_order_reservations, if: :cancelled_status?

  # Historia statusów
  after_create :log_status_change
  after_update :log_status_change, if: :saved_change_to_status?

  def status_name
    STATUS_NAMES[status.to_sym] || status
  end

  def to_param
    order_number
  end

  def order_paid?
    return false if total_amount.zero?
    (paid_amount || 0) == total_amount
  end


  def payment_badge_class
    return "badge-neutral" if total_amount.zero?
    order_paid? ? "badge-success" : "badge-error"
  end

  # Ransack - dozwolone atrybuty do wyszukiwania
  def self.ransackable_attributes(auth_object = nil)
    %w[order_number email phone status created_at total_amount payment_method shipping_method shipping_cost]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[customer shipping_address billing_address order_items]
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

  # Finalizacja zamówienia (paid)
  def finalize_order_stock
    transaction do
      order_items.includes(:product, :product_reservation).each do |item|
        next unless item.product

        # Sprawdź czy rezerwacja istnieje i jest pending
        reservation = item.product_reservation
        next unless reservation&.pending?

        # 1. Zmniejsz fizyczny stan
        item.product.product_stock.decrease_for_order!(
          item.quantity,
          order_item: item
        )

        # 2. Oznacz rezerwację jako fulfilled
        reservation.completed!
      end
    end
  end

  # Anulowanie zamówienia
  def cancel_order_reservations
    product_reservations.pending.each(&:cancel!)
  end

  def log_status_change
    order_status_histories.create!(
      status: status
    )
  end
end
