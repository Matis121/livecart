class LiveChatMessage < ApplicationRecord
  belongs_to :transmission

  enum :platform, { tiktok: 0, facebook: 1, instagram: 2 }

  validates :sender_id, :sender_name, :body, presence: true

  scope :chronological, -> { order(:created_at, :id) }
end
