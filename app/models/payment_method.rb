class PaymentMethod < ApplicationRecord
  acts_as_list scope: :account
  belongs_to :account
  belongs_to :integration, optional: true

  validates :name, presence: true

  scope :active, -> { where(active: true).order(:position) }

  def manual?
    integration_id.nil?
  end

  def gateway?
    integration_id.present?
  end

  def gateway_name
    integration&.provider&.capitalize
  end

  def gateway_configured?
    return true if manual?
    integration&.credentials_present? || false
  end
end
