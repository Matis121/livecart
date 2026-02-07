class AddStockFinalizedToOrders < ActiveRecord::Migration[8.0]
  def change
    add_column :orders, :stock_finalized, :boolean, default: false, null: false
  end
end
