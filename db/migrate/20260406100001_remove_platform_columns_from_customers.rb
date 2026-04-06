class RemovePlatformColumnsFromCustomers < ActiveRecord::Migration[7.2]
  def up
    remove_index :customers, name: "index_customers_on_account_id_and_platform_username"
    remove_column :customers, :platform
    remove_column :customers, :platform_username
    remove_column :customers, :platform_user_id

    # Normalize empty strings to NULL so the unique index works correctly
    execute "UPDATE customers SET email = NULL WHERE email = ''"

    add_index :customers, [:account_id, :email],
      unique: true,
      where: "email IS NOT NULL AND email != ''",
      name: "index_customers_on_account_id_and_email_unique"
  end

  def down
    remove_index :customers, name: "index_customers_on_account_id_and_email_unique"

    add_column :customers, :platform_user_id, :string
    add_column :customers, :platform_username, :string
    add_column :customers, :platform, :string

    add_index :customers, [:account_id, :platform_username],
      unique: true,
      where: "(platform_username IS NOT NULL)",
      name: "index_customers_on_account_id_and_platform_username"
  end
end
