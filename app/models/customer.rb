class Customer < ApplicationRecord
  belongs_to :account
  has_many :orders, dependent: :nullify

  validates :first_name, presence: true
  validates :last_name, presence: true

  def name
    "#{first_name} #{last_name}"
  end

  # Ransack - dozwolone atrybuty do wyszukiwania
  def self.ransackable_attributes(auth_object = nil)
    %w[first_name last_name email phone]
  end

  def self.ransackable_associations(auth_object = nil)
    []
  end
end
