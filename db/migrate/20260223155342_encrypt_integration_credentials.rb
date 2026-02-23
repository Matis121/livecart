class EncryptIntegrationCredentials < ActiveRecord::Migration[8.0]
  def up
    # Allow reading plaintext values that aren't encrypted yet
    ActiveRecord::Encryption.config.support_unencrypted_data = true
    Integration.find_each(&:encrypt)
  ensure
    ActiveRecord::Encryption.config.support_unencrypted_data = false
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
