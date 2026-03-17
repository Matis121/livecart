class ShippingAddress < ApplicationRecord
  belongs_to :order

  COUNTRIES = [
    [ "Polska", "PL" ], [ "Austria", "AT" ], [ "Belgia", "BE" ], [ "Bułgaria", "BG" ],
    [ "Chorwacja", "HR" ], [ "Cypr", "CY" ], [ "Czechy", "CZ" ], [ "Dania", "DK" ],
    [ "Estonia", "EE" ], [ "Finlandia", "FI" ], [ "Francja", "FR" ], [ "Grecja", "GR" ],
    [ "Hiszpania", "ES" ], [ "Holandia", "NL" ], [ "Irlandia", "IE" ], [ "Litwa", "LT" ],
    [ "Luksemburg", "LU" ], [ "Łotwa", "LV" ], [ "Malta", "MT" ], [ "Niemcy", "DE" ],
    [ "Portugalia", "PT" ], [ "Rumunia", "RO" ], [ "Słowacja", "SK" ], [ "Słowenia", "SI" ],
    [ "Szwecja", "SE" ], [ "Węgry", "HU" ], [ "Włochy", "IT" ],
    [ "Norwegia", "NO" ], [ "Szwajcaria", "CH" ], [ "Ukraina", "UA" ],
    [ "Wielka Brytania", "GB" ], [ "Stany Zjednoczone", "US" ]
  ].freeze

  # Walidacje wymagane tylko gdy zamówienie nie jest szkicem
  validates :first_name, presence: true, unless: -> { order&.draft_status? }
  validates :last_name, presence: true, unless: -> { order&.draft_status? }
  validates :address_line1, presence: true, unless: -> { order&.draft_status? }
  validates :city, presence: true, unless: -> { order&.draft_status? }
  validates :postal_code, presence: true, unless: -> { order&.draft_status? }
  validates :country, presence: true, unless: -> { order&.draft_status? }

  def country_name
    COUNTRIES.find { |_name, code| code == country }&.first || country
  end

  def self.ransackable_attributes(auth_object = nil)
    %w[first_name last_name address_line1 city postal_code country]
  end
end
