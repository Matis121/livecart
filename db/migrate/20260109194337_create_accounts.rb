class CreateAccounts < ActiveRecord::Migration[8.0]
  def change
    create_table :accounts do |t|
      t.string :company_name, null: false
      t.string :nip, null: false

      t.timestamps
    end
  end
end
