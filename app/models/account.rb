class Account < ApplicationRecord
  has_many :users
  has_many :products
  has_many :customers

  validates :company_name, presence: true
  validates :nip, presence: true, uniqueness: true
end
