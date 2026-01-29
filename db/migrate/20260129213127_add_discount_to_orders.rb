class AddDiscountToOrders < ActiveRecord::Migration[8.0]
  def change
    add_reference :orders, :discount_code, null: true, foreign_key: true
    add_column :orders, :discount_amount, :decimal, precision: 8, scale: 2, default: 0, null: false
  end
end
