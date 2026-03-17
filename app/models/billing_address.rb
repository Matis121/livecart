class BillingAddress < ApplicationRecord
  belongs_to :order

  COUNTRIES = ShippingAddress::COUNTRIES

  # Walidacje wymagane tylko gdy zamówienie nie jest szkicem I potrzebna jest faktura
  validates :company_name, presence: true, if: -> { needs_invoice? && !order&.draft_status? }
  validates :first_name, presence: true, if: -> { needs_invoice? && !order&.draft_status? }
  validates :last_name, presence: true, if: -> { needs_invoice? && !order&.draft_status? }
  validates :address_line1, presence: true, if: -> { needs_invoice? && !order&.draft_status? }
  validates :city, presence: true, if: -> { needs_invoice? && !order&.draft_status? }
  validates :postal_code, presence: true, if: -> { needs_invoice? && !order&.draft_status? }
  validates :country, presence: true, if: -> { needs_invoice? && !order&.draft_status? }

  def country_name
    COUNTRIES.find { |_name, code| code == country }&.first || country
  end

  def self.ransackable_attributes(auth_object = nil)
    %w[company_name nip first_name last_name address_line1 city]
  end
end
