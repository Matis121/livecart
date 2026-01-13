class RenameStockMovementsToProductStockMovements < ActiveRecord::Migration[8.0]
  def change
    rename_table :stock_movements, :product_stock_movements
  end
end
