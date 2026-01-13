class AddDefaultValueToProductStockQuantity < ActiveRecord::Migration[8.0]
  def change
    change_column_default :product_stocks, :quantity, from: nil, to: 0
  end
end
