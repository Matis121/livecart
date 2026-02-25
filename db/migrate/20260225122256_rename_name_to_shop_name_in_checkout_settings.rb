class RenameNameToShopNameInCheckoutSettings < ActiveRecord::Migration[8.0]
  def up
    execute <<-SQL
      UPDATE accounts
      SET checkout_settings = checkout_settings - 'name' || jsonb_build_object('shop_name', checkout_settings->'name')
      WHERE checkout_settings ? 'name'
    SQL
  end

  def down
    execute <<-SQL
      UPDATE accounts
      SET checkout_settings = checkout_settings - 'shop_name' || jsonb_build_object('name', checkout_settings->'shop_name')
      WHERE checkout_settings ? 'shop_name'
    SQL
  end
end
