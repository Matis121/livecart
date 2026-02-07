class AllowNullOrderItemInProductStockMovements < ActiveRecord::Migration[8.0]
  def change
    change_column_null :product_stock_movements, :order_item_id, true
  end
end
