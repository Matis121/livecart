class FixIntegrationsForAccountScoping < ActiveRecord::Migration[8.0]
  def change
    # Add account_id to integrations (multi-tenant scoping)
    add_column :integrations, :account_id, :bigint
    add_foreign_key :integrations, :accounts
    add_index :integrations, :account_id
    
    # Copy account_id from user.account_id for existing integrations
    reversible do |dir|
      dir.up do
        execute <<-SQL
          UPDATE integrations 
          SET account_id = users.account_id 
          FROM users 
          WHERE integrations.user_id = users.id
        SQL
        
        change_column_null :integrations, :account_id, false
      end
    end
    
    # Change unique index from user+provider to account+provider
    remove_index :integrations, name: "index_integrations_on_user_and_provider"
    add_index :integrations, [:account_id, :provider], unique: true, name: "index_integrations_on_account_and_provider"
    
    # Add integration_type enum (marketplace, social_media, payment, shipping, invoicing)
    add_column :integrations, :integration_type, :integer, default: 0, null: false
    add_index :integrations, :integration_type
  end
end
