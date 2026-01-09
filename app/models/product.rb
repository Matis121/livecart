class Product < ApplicationRecord
  belongs_to :account
  has_many_attached :images

  validates :name, presence: true
  validates :gross_price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :tax_rate, inclusion: { in: [ 0, 5, 8, 23 ] }
  validates :images, content_type: [ "image/png", "image/jpeg" ],
                   size: { less_than: 5.megabytes }
  validates :quantity, presence: true
  validates :currency, presence: true, inclusion: { in: [ "PLN", "EUR", "USD" ] }
end
