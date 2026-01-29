class CreateDiscountCodes < ActiveRecord::Migration[8.0]
  def change
    create_table :discount_codes do |t|
      t.string :code, null: false
      t.string :name
      t.text :description
      t.integer :kind, null: false, default: 0
      t.decimal :value, precision: 8, scale: 2, null: false
      t.decimal :minimum_order_amount, precision: 8, scale: 2
      t.boolean :free_shipping, default: false
      t.datetime :valid_from
      t.datetime :valid_until
      t.integer :usage_limit
      t.integer :used_count, default: 0
      t.boolean :active, default: false
      t.references :account, null: false, foreign_key: true

      t.timestamps
    end
    add_index :discount_codes, :code
  end
end
