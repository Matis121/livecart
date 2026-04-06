class CreateCustomerPlatformAccounts < ActiveRecord::Migration[7.2]
  def up
    create_table :customer_platform_accounts do |t|
      t.references :customer, null: false, foreign_key: true
      t.bigint :account_id, null: false
      t.string :platform, null: false
      t.string :platform_username
      t.string :platform_user_id
      t.timestamps
    end

    # One platform per customer
    add_index :customer_platform_accounts, [:customer_id, :platform], unique: true

    # Unique username within an account+platform
    add_index :customer_platform_accounts,
      [:account_id, :platform, :platform_username],
      unique: true,
      where: "platform_username IS NOT NULL",
      name: "index_cpa_on_account_platform_username"

    # Migrate existing data
    execute <<~SQL
      INSERT INTO customer_platform_accounts (customer_id, account_id, platform, platform_username, platform_user_id, created_at, updated_at)
      SELECT id, account_id, platform, platform_username, platform_user_id, NOW(), NOW()
      FROM customers
      WHERE platform IS NOT NULL
    SQL
  end

  def down
    drop_table :customer_platform_accounts
  end
end
