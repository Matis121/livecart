class ChangeCustomerIdToNullableInOrders < ActiveRecord::Migration[8.0]
  def change
    change_column_null :orders, :customer_id, true
  end
end
