class CreateBillingAddresses < ActiveRecord::Migration[8.0]
  def change
    create_table :billing_addresses do |t|
      t.references :order, null: false, foreign_key: true
      t.boolean :needs_invoice
      t.string :company_name
      t.string :nip
      t.string :first_name
      t.string :last_name
      t.string :address_line1
      t.string :address_line2
      t.string :city
      t.string :postal_code
      t.string :country

      t.timestamps
    end
  end
end
