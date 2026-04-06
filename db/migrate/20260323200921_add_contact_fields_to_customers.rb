class AddContactFieldsToCustomers < ActiveRecord::Migration[8.0]
  def change
    add_column :customers, :email, :string
    add_column :customers, :phone, :string

    change_column_null :customers, :first_name, true
    change_column_null :customers, :last_name, true

    add_index :customers, [ :account_id, :platform_username ],
              unique: true,
              where: "platform_username IS NOT NULL",
              name: "index_customers_on_account_id_and_platform_username"
  end
end
