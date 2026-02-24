# app/models/account.rb
class Account < ApplicationRecord
  has_many :users
  has_many :products
  has_many :customers
  has_many :orders
  has_many :discount_codes
  has_many :shipping_methods
  has_many :payment_methods
  has_many :transmissions
  has_many :product_imports
  has_many :integrations

  has_one_attached :logo

  validates :company_name, presence: true, length: { maximum: 30 }, uniqueness: true
  validates :nip, presence: true, uniqueness: true
  validates :slug, presence: true, uniqueness: true, format: { with: /\A[a-z0-9\-]+\z/ }

  before_validation :generate_slug

  store_accessor :checkout_settings,
    :name,
    :time_to_pay,
    :time_to_pay_active,
    :open_package_enabled

  def open_package_enabled?
    open_package_enabled == "1"
  end

  store_accessor :terms,
    :terms_content,
    :privacy_policy_content

  after_initialize :set_default_checkout_settings, if: :new_record?
  after_initialize :set_default_terms, if: :new_record?

  private

  def generate_slug
    source_name = name.presence || company_name
    return if source_name.blank?

    # Regenerate slug on create or when shop name changes
    if new_record? || checkout_settings_changed?
      base_slug = source_name.parameterize
      self.slug = base_slug
      counter = 1
      while Account.where(slug: self.slug).where.not(id: id).exists?
        self.slug = "#{base_slug}-#{counter}"
        counter += 1
      end
    end
  end

  def set_default_checkout_settings
    self.checkout_settings ||= {
      name: company_name,
      time_to_pay: "0",
      time_to_pay_active: "0",
      open_package_enabled: "0"
    }
  end

  def set_default_terms
    self.terms ||= {
      terms_content: "",
      privacy_policy_content: ""
    }
  end
end
