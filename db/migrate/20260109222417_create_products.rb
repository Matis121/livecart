class CreateProducts < ActiveRecord::Migration[8.0]
  def change
    create_table :products do |t|
      t.references :account, null: false, foreign_key: true
      t.string :name
      t.string :ean
      t.string :sku
      t.integer :tax_rate
      t.decimal :gross_price
      t.integer :quantity
      t.string :currency

      t.timestamps
    end
  end
end
