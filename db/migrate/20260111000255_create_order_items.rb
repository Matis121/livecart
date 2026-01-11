class CreateOrderItems < ActiveRecord::Migration[8.0]
  def change
    create_table :order_items do |t|
      t.references :order, null: false, foreign_key: true
      t.references :product, null: true, foreign_key: true
      t.string :name, null: false
      t.string :ean, null: false
      t.string :sku, null: false
      t.decimal :unit_price, null: false
      t.integer :quantity, null: false
      t.decimal :total_price, null: false

      t.timestamps
    end
  end
end
