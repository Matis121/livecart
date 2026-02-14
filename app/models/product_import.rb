class ProductImport < ApplicationRecord
  belongs_to :account
  belongs_to :user, optional: true

  enum :status, { pending: 0, processing: 1, completed: 2, failed: 3 }, prefix: :import

  STATUS_NAMES = {
    pending: "Oczekujące",
    processing: "W trakcie",
    completed: "Zakończone",
    failed: "Nieudane"
  }.freeze

  DUPLICATE_STRATEGIES_NAMES = {
    skip_duplicate_sku: "Pomiń duplikaty SKU",
    skip_duplicate_ean: "Pomiń duplikaty EAN",
    skip_duplicate_name: "Pomiń duplikaty nazwy",
    import_all: "Importuj wszystkie"
  }

  attribute :error_details, :json, default: []

  validates :import_name, presence: true
  validates :total_rows, numericality: { greater_than_or_equal_to: 0 }
  validates :duplicate_strategy, presence: true, inclusion: {
    in: %w[skip_duplicate_sku skip_duplicate_ean skip_duplicate_name import_all],
    message: "nieprawidłowa strategia"
  }


  scope :recent, -> { order(created_at: :desc) }
  scope :for_account, ->(account) { where(account: account) }


  def formatted_errors
    return [] unless error_details.is_a?(Array)
    error_details.first(10).map do |e|
      "Wiersz #{e['row']}: #{e['messages']&.join(', ')}"
    end
  end
end
