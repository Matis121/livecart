class OrderTransmission < ApplicationRecord
  belongs_to :order
  belongs_to :transmission
end
