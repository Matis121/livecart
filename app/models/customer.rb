class Customer < ApplicationRecord
  belongs_to :account
  has_many :orders, dependent: :nullify
  has_many :platform_accounts, class_name: "CustomerPlatformAccount", dependent: :destroy

  store_accessor :default_shipping_address,
    :shipping_first_name, :shipping_last_name,
    :shipping_address_line1, :shipping_address_line2,
    :shipping_city, :shipping_postal_code, :shipping_country

  store_accessor :default_billing_data,
    :billing_needs_invoice, :billing_company_name, :billing_nip,
    :billing_first_name, :billing_last_name,
    :billing_address_line1, :billing_address_line2,
    :billing_city, :billing_postal_code, :billing_country

  # Virtual attributes — proxy to first platform account for admin form compatibility
  def platform
    if instance_variable_defined?(:@assigned_platform)
      @assigned_platform
    else
      platform_accounts.first&.platform
    end
  end

  def platform=(val)
    @assigned_platform = val.presence
  end

  def platform_username
    if instance_variable_defined?(:@assigned_platform_username)
      @assigned_platform_username
    else
      platform_accounts.first&.platform_username
    end
  end

  def platform_username=(val)
    @assigned_platform_username = val.to_s.delete_prefix("@").strip.presence
  end

  def platform_customer?
    if instance_variable_defined?(:@assigned_platform)
      @assigned_platform.present?
    else
      platform_accounts.exists?
    end
  end

  # Sync virtual platform attrs to platform_accounts after save
  after_save :sync_platform_account, if: -> { instance_variable_defined?(:@assigned_platform) }

  validates :first_name, length: { maximum: 50 }
  validates :last_name, length: { maximum: 50 }

  before_validation { self.email = email.presence }

  validates :email,
    format: { with: URI::MailTo::EMAIL_REGEXP, message: "jest nieprawidłowy" },
    uniqueness: { scope: :account_id, message: "email jest już zarejestrowany w sklepie" },
    allow_blank: true

  validates :phone,
    format: { with: /\A\+\d{1,4}\d{9}\z/, message: "numer musi mieć dokładnie 9 cyfr" },
    uniqueness: { scope: :account_id, message: "telefon jest już zarejestrowany w sklepie" },
    if: -> { phone.present? }

  def name
    return platform_username.to_s if first_name.blank? && last_name.blank?
    "#{first_name} #{last_name}".strip
  end

  def has_saved_shipping_address?
    shipping_address_line1.present?
  end

  def has_saved_billing_data?
    billing_needs_invoice == "1" && billing_address_line1.present?
  end

  def save_shipping_from_order!(order)
    sa = order.shipping_address
    return unless sa.address_line1.present?
    update_columns(default_shipping_address: {
      "shipping_first_name"    => sa.first_name,
      "shipping_last_name"     => sa.last_name,
      "shipping_address_line1" => sa.address_line1,
      "shipping_address_line2" => sa.address_line2,
      "shipping_city"          => sa.city,
      "shipping_postal_code"   => sa.postal_code,
      "shipping_country"       => sa.country
    })
  end

  def save_billing_from_order!(order)
    ba = order.billing_address
    update_columns(default_billing_data: {
      "billing_needs_invoice"  => ba.needs_invoice? ? "1" : "0",
      "billing_company_name"   => ba.company_name,
      "billing_nip"            => ba.nip,
      "billing_first_name"     => ba.first_name,
      "billing_last_name"      => ba.last_name,
      "billing_address_line1"  => ba.address_line1,
      "billing_address_line2"  => ba.address_line2,
      "billing_city"           => ba.city,
      "billing_postal_code"    => ba.postal_code,
      "billing_country"        => ba.country
    })
  end

  # Find by email first, then phone, then create — used at checkout
  def self.find_or_create_for_checkout(account:, email:, phone: nil)
    return nil if email.blank?

    account.customers.find_by(email: email) ||
      (phone.present? && account.customers.find_by(phone: phone)) ||
      account.customers.create!(email: email, phone: phone.presence)
  end

  # Find by existing platform account; if not found, link to existing customer by email or create new
  def self.find_or_link_platform(account:, platform:, platform_username:, email: nil, phone: nil)
    clean_username = platform_username.to_s.delete_prefix("@").strip

    existing = CustomerPlatformAccount.find_by(
      account_id: account.id,
      platform: platform,
      platform_username: clean_username
    )
    return existing.customer if existing

    customer = (email.present? && account.customers.find_by(email: email)) ||
               account.customers.create!(email: email.presence, phone: phone.presence)

    customer.platform_accounts.create!(
      account_id: account.id,
      platform: platform,
      platform_username: clean_username
    )
    customer
  end

  def self.ransackable_attributes(auth_object = nil)
    %w[first_name last_name email phone]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[platform_accounts]
  end

  private

  def sync_platform_account
    if @assigned_platform.blank?
      platform_accounts.destroy_all
    else
      pa = platform_accounts.find_or_initialize_by(platform: @assigned_platform, account_id: account_id)
      pa.platform_username = @assigned_platform_username
      unless pa.save
        pa.errors.each { |e| errors.add(e.attribute, e.message) }
        raise ActiveRecord::Rollback
      end
    end
    remove_instance_variable(:@assigned_platform)
    remove_instance_variable(:@assigned_platform_username) if instance_variable_defined?(:@assigned_platform_username)
  end
end
