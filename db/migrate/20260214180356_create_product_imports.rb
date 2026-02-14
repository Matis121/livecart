class CreateProductImports < ActiveRecord::Migration[7.0]
  def change
    create_table :product_imports do |t|
      t.references :account, null: false, foreign_key: true
      t.string :import_name, null: false
      t.integer :status, default: 0, null: false
      t.integer :duplicate_strategy, default: 0
      t.integer :total_rows, default: 0
      t.integer :success_count, default: 0
      t.integer :skipped_count, default: 0
      t.integer :error_count, default: 0
      t.text :error_details
      t.datetime :started_at
      t.datetime :completed_at

      t.timestamps
    end

    add_index :product_imports, [ :account_id, :created_at ]
    add_index :product_imports, :status
  end
end
