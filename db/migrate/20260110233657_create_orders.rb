class CreateOrders < ActiveRecord::Migration[8.0]
  def change
    create_table :orders do |t|
      t.references :account, null: false, foreign_key: true
      t.references :customer, null: false, foreign_key: true
      t.string :order_number, null: false
      t.string :order_token, null: false
      t.string :status, null: false
      t.string :email
      t.string :phone
      t.decimal :total_amount, null: false
      t.decimal :shipping_cost, null: false, default: 0.00
      t.string :currency, null: false, default: "PLN"
      t.string :shipping_method
      t.text :comment

      t.timestamps
    end
  end
end
