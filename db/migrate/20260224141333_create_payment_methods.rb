class CreatePaymentMethods < ActiveRecord::Migration[8.0]
  def change
    create_table :payment_methods do |t|
      t.references :account, null: false, foreign_key: true
      t.references :integration, null: true, foreign_key: true
      t.string :name, null: false
      t.text :description
      t.boolean :active, default: true
      t.integer :position, default: 0

      t.timestamps
    end
  end
end
