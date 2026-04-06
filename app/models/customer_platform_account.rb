class CustomerPlatformAccount < ApplicationRecord
  belongs_to :customer
  belongs_to :account

  PLATFORMS = %w[tiktok instagram].freeze
  USERNAME_REGEX = /\A[a-zA-Z0-9._]{1,64}\z/

  before_validation :normalize_username

  validates :platform, presence: true, inclusion: { in: PLATFORMS }
  validates :platform,
    uniqueness: { scope: :customer_id, message: "klient ma już konto na tej platformie" }
  validates :platform_username,
    format: { with: USERNAME_REGEX, message: "może zawierać tylko litery, cyfry, kropki i podkreślniki" },
    uniqueness: { scope: [:account_id, :platform], message: "nick jest już zarejestrowany w sklepie na tej platformie" },
    allow_blank: true

  def self.ransackable_attributes(auth_object = nil)
    %w[platform_username platform]
  end

  private

  def normalize_username
    self.platform_username = platform_username.to_s.delete_prefix("@").strip.presence
  end
end
