class AddPaymentFieldsToOrders < ActiveRecord::Migration[8.0]
  def change
    add_column :orders, :payment_method, :string
    add_column :orders, :paid_amount, :decimal, default: 0.0, null: false
  end
end
