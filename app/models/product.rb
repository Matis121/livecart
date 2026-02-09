class Product < ApplicationRecord
  belongs_to :account
  has_many_attached :images

  has_one :product_stock, dependent: :destroy
  has_many :product_stock_movements, dependent: :destroy
  has_many :order_items, dependent: :nullify

  accepts_nested_attributes_for :product_stock


  delegate :quantity,
           to: :product_stock, prefix: false, allow_nil: true

  validates :name, presence: true
  validates :gross_price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :tax_rate, inclusion: { in: [ 0, 5, 8, 23 ] }
  validates :images, content_type: [ "image/png", "image/jpeg" ],
                   size: { less_than: 5.megabytes }
  validates :currency, presence: true, inclusion: { in: [ "PLN", "EUR", "USD" ] }

  # Ransack configuration
  def self.ransackable_attributes(auth_object = nil)
    [ "name", "sku", "ean", "gross_price", "created_at", "updated_at" ]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "product_stock" ]
  end
end
