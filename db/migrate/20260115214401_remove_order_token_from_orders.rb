class RemoveOrderTokenFromOrders < ActiveRecord::Migration[8.0]
  def change
    remove_column :orders, :order_token, :string
  end
end
