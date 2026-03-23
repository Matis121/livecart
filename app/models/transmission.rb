class Transmission < ApplicationRecord
  belongs_to :account
  belongs_to :integration, optional: true
  has_many :transmission_items, dependent: :destroy
  has_many :orders, dependent: :nullify

  validates :name, presence: true

  enum :status, {
    active: 1,
    processing: 2,
    completed: 3,
    cancelled: 4
  }

  def live_linked?
    integration_id.present? && live_room_id.present?
  end

  def live_platform
    integration&.provider
  end
end
