class ShippingAddress < ApplicationRecord
  belongs_to :order

  # Walidacje wymagane tylko gdy zamówienie nie jest szkicem
  validates :first_name, presence: true, unless: -> { order&.draft_status? }
  validates :last_name, presence: true, unless: -> { order&.draft_status? }
  validates :address_line1, presence: true, unless: -> { order&.draft_status? }
  validates :city, presence: true, unless: -> { order&.draft_status? }
  validates :postal_code, presence: true, unless: -> { order&.draft_status? }
  validates :country, presence: true, unless: -> { order&.draft_status? }

  def self.ransackable_attributes(auth_object = nil)
    %w[first_name last_name address_line1 city postal_code]
  end
end
