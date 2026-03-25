class Customer < ApplicationRecord
  belongs_to :account
  has_many :orders, dependent: :nullify

  TIKTOK_USERNAME_REGEX = /\A[a-zA-Z0-9._]{3,24}\z/

  before_validation :normalize_platform_username, if: :platform_customer?

  validates :first_name, presence: true, length: { maximum: 50 }, unless: :platform_customer?
  validates :last_name, length: { maximum: 50 }, unless: :platform_customer?


  with_options if: :platform_customer? do
    validates :platform_username, presence: true
    validates :platform_username,
              format: { with: TIKTOK_USERNAME_REGEX, message: "może zawierać tylko litery, cyfry, kropki i podkreślniki (3-24 znaki)" },
              allow_blank: true
    validates :platform_username,
              format: { without: /\.\z/, message: "nie może kończyć się kropką" },
              uniqueness: { scope: :account_id, message: "nick jest już zarejestrowany w sklepie" },
              allow_blank: true
  end

  validates :email,
            presence: true,
            format: { with: URI::MailTo::EMAIL_REGEXP, message: "jest nieprawidłowy", allow_blank: true },
            uniqueness: { scope: :account_id, message: "email jest już zarejestrowany w sklepie", allow_blank: true },
            if: :platform_customer?

  validates :phone,
            format: { with: /\A\+\d{1,4}\d{9}\z/, message: "numer musi mieć dokładnie 9 cyfr" },
            uniqueness: { scope: :account_id, message: "telefon jest już zarejestrowany w sklepie" },
            if: -> { phone.present? }

  def name
    return platform_username.to_s if first_name.blank? && last_name.blank?
    "#{first_name} #{last_name}".strip
  end

  def platform_customer?
    platform.present?
  end

  private

  def normalize_platform_username
    self.platform_username = platform_username.to_s.delete_prefix("@").strip
  end

  # Ransack - dozwolone atrybuty do wyszukiwania
  def self.ransackable_attributes(auth_object = nil)
    %w[first_name last_name email phone platform platform_username]
  end

  def self.ransackable_associations(auth_object = nil)
    []
  end
end
