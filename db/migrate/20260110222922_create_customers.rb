class CreateCustomers < ActiveRecord::Migration[8.0]
  def change
    create_table :customers do |t|
      t.references :account, null: false, foreign_key: true
      t.string :platform_user_id
      t.string :platform
      t.string :platform_username
      t.string :first_name, null: false
      t.string :last_name, null: false
      t.json :profile_data

      t.timestamps
    end
  end
end
