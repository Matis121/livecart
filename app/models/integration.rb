class Integration < ApplicationRecord
  belongs_to :account
  belongs_to :user
  has_many :integration_exports, dependent: :destroy

  enum :integration_type, {
    marketplace: 0,      # Baselinker, Sellasist
    social_media: 1,     # TikTok, Facebook, Instagram
    payment: 2,          # Stripe, PayU, Przelewy24
    shipping: 3,         # InPost, DHL, DPD
    invoicing: 4,        # Fakturownia, Wfirma
    accounting: 5        # Future: other accounting systems
  }, prefix: :type

  enum :status, {
    active: "active",
    inactive: "inactive",
    error: "error",
    pending_auth: "pending_auth"
  }, prefix: :status

  INTEGRATION_TYPE_NAMES = {
    marketplace: "Marketplace",
    social_media: "Social Media",
    payment: "Płatności",
    shipping: "Przesyłki",
    invoicing: "Faktury",
    accounting: "Księgowość"
  }.freeze

  encrypts :api_key
  encrypts :api_secret
  encrypts :access_token
  encrypts :refresh_token

  # Validations
  validates :provider, presence: true
  validates :account_id, presence: true
  validates :user_id, presence: true
  validates :integration_type, presence: true
  validates :status, presence: true

  # Scopes
  scope :active, -> { where(status: "active") }
  scope :inactive, -> { where(status: "inactive") }
  scope :by_type, ->(type) { where(integration_type: type) }
  scope :for_provider, ->(provider) { where(provider: provider) }
  scope :needs_sync, -> {
    where("last_synced_at IS NULL OR last_synced_at < ?", 15.minutes.ago)
  }

  # Class methods
  def self.integration_type_label(type)
    INTEGRATION_TYPE_NAMES[type.to_sym] || type.to_s.humanize
  end

  def self.provider_options
    {
      "Marketplace" => [
        [ "Baselinker", "baselinker" ],
        [ "Sellasist", "sellasist" ]
      ],
      "Social Media" => [
        [ "TikTok", "tiktok" ],
        [ "Facebook", "facebook" ],
        [ "Instagram", "instagram" ]
      ],
      "Płatności" => [
        [ "Stripe", "stripe" ],
        [ "PayU", "payu" ],
        [ "Przelewy24", "przelewy24" ]
      ],
      "Przesyłki" => [
        [ "InPost", "inpost" ],
        [ "DHL", "dhl" ],
        [ "DPD", "dpd" ]
      ],
      "Faktury" => [
        [ "Fakturownia", "fakturownia" ],
        [ "Wfirma", "wfirma" ]
      ]
    }
  end

  def self.integration_type_for_provider(provider)
    case provider.to_s.downcase
    when "baselinker", "sellasist"
      :marketplace
    when "tiktok", "facebook", "instagram"
      :social_media
    when "stripe", "payu", "przelewy24"
      :payment
    when "inpost", "dhl", "dpd"
      :shipping
    when "fakturownia", "wfirma"
      :invoicing
    else
      :marketplace
    end
  end

  # Instance methods
  def provider_name
    provider.capitalize
  end

  def sync_enabled?
    status_active? && (type_marketplace? || type_social_media?)
  end

  def can_sync?
    sync_enabled? && credentials_present?
  end

  def credentials_present?
    case provider.to_s.downcase
    when "baselinker", "sellasist"
      api_key.present?
    when "tiktok", "facebook", "instagram"
      access_token.present?
    when "stripe", "payu", "przelewy24"
      api_key.present? && api_secret.present?
    when "inpost", "dhl", "dpd", "fakturownia", "wfirma"
      api_key.present?
    else
      api_key.present?
    end
  end

  def requires_api_secret?
    %w[stripe payu przelewy24].include?(provider.to_s.downcase)
  end

  def mark_sync_success!
    update!(
      last_synced_at: Time.current,
      last_error_message: nil,
      status: "active"
    )
  end

  def mark_sync_error!(error_message)
    update!(
      last_synced_at: Time.current,
      last_error_message: error_message,
      status: "error"
    )
  end

  def status_badge_class
    case status
    when "active"
      "badge-success"
    when "inactive"
      "badge-neutral"
    when "error"
      "badge-error"
    when "pending_auth"
      "badge-warning"
    else
      "badge-ghost"
    end
  end

  def status_name
    I18n.t("integrations.statuses.#{status}", default: status.humanize)
  end

  def integration_type_name
    INTEGRATION_TYPE_NAMES[integration_type.to_sym] || integration_type.humanize
  end

  # Baselinker-specific settings helpers
  def stock_sync_enabled?
    return true unless provider == "baselinker"
    settings.dig("stock_sync_enabled") != false
  end

  def price_sync_enabled?
    return true unless provider == "baselinker"
    settings.dig("price_sync_enabled") != false
  end

  def order_status_sync_enabled?
    return false unless provider == "baselinker"
    ActiveModel::Type::Boolean.new.cast(settings.dig("order_status_sync_enabled"))
  end

  def stock_match_by
    settings.dig("stock_match_by") || "sku"
  end

  def price_match_by
    settings.dig("price_match_by") || "sku"
  end

  def export_order_status
    settings.dig("export_order_status") || "paid"
  end

  def baselinker_status_id
    settings.dig("baselinker_status_id")
  end

  def inventory_id
    settings.dig("inventory_id")
  end

  # Mapping of Baselinker status IDs to LiveCart order statuses
  # Example: { "123" => "shipped", "456" => "delivered" }
  def status_mapping
    settings.dig("status_mapping") || {}
  end

  # Last processed Baselinker journal log ID (for incremental sync)
  def last_journal_log_id
    settings.dig("last_journal_log_id").to_i
  end

  def update_last_journal_log_id!(log_id)
    update_baselinker_settings("last_journal_log_id" => log_id.to_s)
  end

  # Update Baselinker settings
  def update_baselinker_settings(new_settings)
    current_settings = settings || {}
    updated_settings = current_settings.merge(new_settings.stringify_keys)
    update(settings: updated_settings)
  end
end
