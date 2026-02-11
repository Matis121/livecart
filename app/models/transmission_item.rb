class TransmissionItem < ApplicationRecord
  belongs_to :transmission
  belongs_to :customer
  belongs_to :product, optional: true

  validates :name, presence: true
  validates :unit_price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :quantity, presence: true, numericality: { greater_than: 0, only_integer: true }
end
