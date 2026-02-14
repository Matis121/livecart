module Products
  class BulkDeleteJob < ApplicationJob
    queue_as :default
    sidekiq_options retry: 2

    def perform(account_id, product_ids)
      account = Account.find(account_id)
      products = account.products.where(id: product_ids)

      count = products.count
      products.destroy_all

      Rails.logger.info "Bulk deleted #{count} products for account #{account_id}"
    end
  end
end
