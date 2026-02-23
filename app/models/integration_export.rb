class IntegrationExport < ApplicationRecord
  belongs_to :order
  belongs_to :integration

  enum :status, {
    pending: 0,
    success: 1,
    failed: 2
  }, prefix: true

  validates :order_id, uniqueness: { scope: :integration_id }

  scope :successful, -> { where(status: :success) }
  scope :failed, -> { where(status: :failed) }

  def mark_success!(external_id)
    update!(
      status: :success,
      external_id: external_id,
      exported_at: Time.current,
      error_message: nil
    )
  end

  def mark_failed!(error)
    update!(
      status: :failed,
      exported_at: Time.current,
      error_message: error
    )
  end

  def can_retry?
    status_failed?
  end
end
