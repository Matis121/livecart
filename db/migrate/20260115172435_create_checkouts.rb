class CreateCheckouts < ActiveRecord::Migration[8.0]
  def change
    create_table :checkouts do |t|
      t.references :order, null: false, foreign_key: true
      t.string :token, null: false
      t.integer :status, null: false, default: 0
      t.datetime :expires_at, null: false
      t.datetime :completed_at
      t.integer :activation_hours, null: false, default: 24

      t.integer :views_count, null: false, default: 0
      t.datetime :last_viewed_at

      t.timestamps
    end

    add_index :checkouts, :token, unique: true
    add_index :checkouts, :status
    add_index :checkouts, :expires_at
  end
end
