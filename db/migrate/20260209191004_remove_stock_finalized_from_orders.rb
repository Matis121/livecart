class RemoveStockFinalizedFromOrders < ActiveRecord::Migration[8.0]
  def change
    remove_column :orders, :stock_finalized, :boolean
  end
end
