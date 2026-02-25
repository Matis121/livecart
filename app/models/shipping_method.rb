class ShippingMethod < ApplicationRecord
  acts_as_list scope: :account
  belongs_to :account

  enum :pickup_point_provider, {
    inpost: 0,
    orlen: 1,
    dpd: 2,
    poczta_polska: 3
  }, prefix: true  # → pickup_point_provider_inpost?, pickup_point_provider_orlen?

  validates :name, presence: true, length: { maximum: 50 }
  validates :price, numericality: { greater_than_or_equal_to: 0 }
  validates :pickup_point_provider, presence: true, if: :is_pickup_point?

  scope :active, -> { where(active: true).order(:position) }

  def free_for?(subtotal)
    free_above.present? && subtotal >= free_above
  end

  def price_for(subtotal)
    free_for?(subtotal) ? 0 : price
  end
end
