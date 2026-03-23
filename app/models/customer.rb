class Customer < ApplicationRecord
  belongs_to :account
  has_many :orders, dependent: :nullify

  validates :first_name, presence: true, length: { maximum: 50 }
  validates :last_name, presence: true, length: { maximum: 50 }

  def name
    "#{first_name} #{last_name}"
  end

  # Ransack - dozwolone atrybuty do wyszukiwania
  def self.ransackable_attributes(auth_object = nil)
    %w[first_name last_name email phone platform platform_username]
  end

  def self.find_or_create_from_platform(account, platform:, user_id:, username:, profile_data: {})
    customer = account.customers.find_or_initialize_by(
      platform: platform,
      platform_user_id: user_id
    )
    customer.assign_attributes(
      platform_username: username,
      first_name: customer.first_name.presence || username,
      last_name: customer.last_name.presence || "-",
      profile_data: (customer.profile_data || {}).merge(profile_data)
    )
    customer.save! if customer.changed?
    customer
  end

  def self.ransackable_associations(auth_object = nil)
    []
  end
end
