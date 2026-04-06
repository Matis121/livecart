class AddDefaultAddressesToCustomers < ActiveRecord::Migration[8.0]
  def change
    add_column :customers, :default_shipping_address, :jsonb
    add_column :customers, :default_billing_data, :jsonb
  end
end
