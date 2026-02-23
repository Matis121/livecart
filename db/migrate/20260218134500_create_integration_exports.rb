class CreateIntegrationExports < ActiveRecord::Migration[8.0]
  def change
    create_table :integration_exports do |t|
      t.references :order, null: false, foreign_key: true
      t.references :integration, null: false, foreign_key: true
      t.string :external_id
      t.datetime :exported_at
      t.integer :status, default: 0, null: false
      t.text :error_message

      t.timestamps
    end

    # Prevent duplicate exports: one order can only be exported once per integration
    add_index :integration_exports, [:order_id, :integration_id], unique: true
  end
end
