class CreateTransmissionItems < ActiveRecord::Migration[8.0]
  def change
    create_table :transmission_items do |t|
      t.references :transmission, null: false, foreign_key: true
      t.references :customer, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.string :name, null: false
      t.string :ean
      t.string :sku
      t.decimal :unit_price, null: false, default: 0, precision: 8, scale: 2
      t.integer :quantity, null: false, default: 1

      t.timestamps
    end
  end
end
