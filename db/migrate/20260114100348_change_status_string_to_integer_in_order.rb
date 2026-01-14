class ChangeStatusStringToIntegerInOrder < ActiveRecord::Migration[8.0]
  def up
    execute "TRUNCATE orders, order_items, shipping_addresses, billing_addresses, product_reservations RESTART IDENTITY CASCADE"

    remove_column :orders, :status

    add_column :orders, :status, :integer, default: 0, null: false
  end

  def down
    execute "TRUNCATE orders RESTART IDENTITY CASCADE"
    remove_column :orders, :status
    add_column :orders, :status, :string
  end
end
