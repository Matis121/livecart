class Account < ApplicationRecord
  has_many :users

  validates :company_name, presence: true
  validates :nip, presence: true, uniqueness: true
end
