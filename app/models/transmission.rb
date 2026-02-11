class Transmission < ApplicationRecord
  belongs_to :account
  has_many :transmission_items, dependent: :destroy
  has_many :orders, dependent: :nullify

  validates :name, presence: true

  enum :status, {
    active: 1,
    processing: 2,
    completed: 3,
    cancelled: 4
  }
end
