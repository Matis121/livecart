class CreateShippingMethods < ActiveRecord::Migration[8.0]
  def change
    create_table :shipping_methods do |t|
      t.references :account, null: false, foreign_key: true
      t.string :name, null: false
      t.decimal :price, precision: 8, scale: 2
      t.decimal :free_above, precision: 8, scale: 2
      t.boolean :is_pickup_point, default: false
      t.integer :pickup_point_provider
      t.integer :position, default: 0
      t.boolean :active, default: true

      t.timestamps
    end
  end
end
