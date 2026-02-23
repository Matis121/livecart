# app/models/account.rb
class Account < ApplicationRecord
  has_many :users
  has_many :products
  has_many :customers
  has_many :orders
  has_many :discount_codes
  has_many :shipping_methods
  has_many :transmissions
  has_many :product_imports
  has_many :integrations

  has_one_attached :logo

  validates :company_name, presence: true
  validates :nip, presence: true, uniqueness: true

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
