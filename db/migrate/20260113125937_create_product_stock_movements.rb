class CreateProductStockMovements < ActiveRecord::Migration[8.0]
  def change
    create_table :product_stock_movements do |t|
      t.references :product, null: false, foreign_key: true
      t.references :order_item, null: false, foreign_key: true
      t.integer :quantity_change, null: false
      t.integer :quantity_before, null: false
      t.integer :quantity_after, null: false
      t.string :movement_type, null: false

      t.timestamps
    end
  end
end
