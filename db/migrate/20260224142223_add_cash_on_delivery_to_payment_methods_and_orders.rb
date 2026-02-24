class AddCashOnDeliveryToPaymentMethodsAndOrders < ActiveRecord::Migration[8.0]
  def change
    add_column :payment_methods, :cash_on_delivery, :boolean, default: false, null: false
    add_column :orders, :cash_on_delivery, :boolean, default: false, null: false
  end
end
