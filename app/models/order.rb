class Order < ApplicationRecord
  belongs_to :account
  belongs_to :customer, optional: true
  belongs_to :discount_code, optional: true
  belongs_to :transmission, optional: true

  has_many :order_items, dependent: :destroy
  has_one :shipping_address, dependent: :destroy
  has_one :billing_address, dependent: :destroy
  has_many :order_status_histories, dependent: :destroy
  has_one :checkout, dependent: :destroy
  has_many :integration_exports, dependent: :destroy

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
    returned: 8,
    open_package: 9
  }, suffix: :status

  STATUS_NAMES = {
    draft: "Szkic",
    offer_sent: "Oferta wysłana",
    open_package: "Otwarta paczka",
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

  # Otwarta paczka — szuka aktywnego zamówienia open_package dla danego klienta
  scope :open_package_for_customer, ->(customer, account) {
    where(customer: customer, account: account, status: :open_package)
      .order(created_at: :desc)
      .limit(1)
  }

  # Dodaje produkty z transmisji do istniejącego zamówienia (otwarta paczka)
  def add_transmission_items!(items, transmission = nil)
    transaction do
      # Ustaw transmission_id jeśli to pierwsza transmisja
      update!(transmission: transmission) if transmission && transmission_id.nil?

      items.each do |item|
        order_items.create!(
          product_id: item.product_id,
          name: item.name,
          ean: item.ean,
          sku: item.sku,
          unit_price: item.unit_price || 0,
          quantity: item.quantity,
        )
      end

      recalculate_total!
    end
  end

  # Generowanie numeru zamówienia
  before_validation :generate_order_number, on: :create, if: -> { order_number.blank? }

  # Adresy
  after_initialize :build_blank_addresses
  after_update :recalculate_total_if_shipping_changed, if: :saved_change_to_shipping_cost?


  # Historia statusów
  after_create :log_status_change
  after_update :log_status_change, if: :saved_change_to_status?
  after_update :export_to_marketplace_integrations, if: :saved_change_to_status?


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


  def apply_discount_code(code_string)
    code_string = code_string.to_s.strip
    if code_string.blank?
      self.discount_code_id = nil
      self.discount_name = nil
      self.discount_amount = 0
      recalculate_total!
      save  # zapisuje discount_code_id, discount_amount i ewent. inne zmiany
      return true
    end

    code = account.discount_codes.find_by("LOWER(code) = ?", code_string.downcase)
    unless code
      errors.add(:base, "Nieprawidłowy kod rabatowy")
      return false
    end

    subtotal = order_items.sum(:total_price)
    unless code.applicable_for?(subtotal)
      errors.add(:base, "Ten kod nie jest ważny lub nie spełnia warunków")
      return false
    end

    self.discount_code_id = code.id
    self.discount_amount = code.discount_for_order(self)
    self.discount_name = code.code
    recalculate_total!
    save   # zapisuje discount_code_id, discount_amount
    true
  end

  def recalculate_total!
    items_total = order_items.sum(:total_price)
    new_total = items_total + (shipping_cost || 0) - (discount_amount || 0)
    new_total = 0 if new_total < 0
    update_column(:total_amount, new_total)
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


  def log_status_change
    order_status_histories.create!(
      status: status
    )
  end

  def export_to_marketplace_integrations
    # Find all active marketplace integrations for this account
    integrations = account.integrations
                         .active
                         .type_marketplace

    return if integrations.empty?

    existing_exports = integration_exports.where(integration: integrations).index_by(&:integration_id)

    integrations.each do |integration|
      # Only export if order status matches configured export status
      next unless status == integration.export_order_status

      # Check if already successfully exported (idempotency)
      existing_export = existing_exports[integration.id]

      if existing_export&.status_success?
        Rails.logger.info("Order #{order_number} already exported to #{integration.provider_name} (external_id: #{existing_export.external_id}) - skipping")
        next
      end

      if existing_export&.status_pending?
        Rails.logger.info("Order #{order_number} export to #{integration.provider_name} already in progress - skipping")
        next
      end

      # Allow retry if failed or no export record exists
      Rails.logger.info("Queuing order #{order_number} for export to #{integration.provider_name}")
      Integrations::ExportOrderJob.perform_later(id, integration.id)
    end
  rescue StandardError => e
    Rails.logger.error("❌ Failed to queue order export: #{e.message}")
    # Don't raise - this shouldn't fail the order status update
  end

  def generate_order_number
    10.times do
      day_of_year = Time.now.strftime("%j")
      random_part = (10000..99999).to_a.sample
      number = "#{day_of_year}#{random_part}"

      unless account.orders.exists?(order_number: number)
        self.order_number = number
        return
      end
    end

    raise "Nie udało się wygenerować unikalnego numeru"
  end
end
