class CreateProductStocks < ActiveRecord::Migration[8.0]
  def change
    create_table :product_stocks do |t|
      t.references :product, null: false, foreign_key: true
      t.integer :quantity, null: false
      t.datetime :last_synced_at
      t.boolean :sync_enabled, null: false, default: false

      t.timestamps
    end
  end
end
