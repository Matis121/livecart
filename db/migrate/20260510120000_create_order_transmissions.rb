class CreateOrderTransmissions < ActiveRecord::Migration[7.1]
  def change
    create_table :order_transmissions do |t|
      t.references :order, null: false, foreign_key: true
      t.references :transmission, null: false, foreign_key: true
      t.timestamps
    end

    add_index :order_transmissions, [:order_id, :transmission_id], unique: true

    # Migracja istniejących danych
    reversible do |dir|
      dir.up do
        execute <<-SQL
          INSERT INTO order_transmissions (order_id, transmission_id, created_at, updated_at)
          SELECT id, transmission_id, NOW(), NOW()
          FROM orders
          WHERE transmission_id IS NOT NULL
        SQL
      end
    end

    remove_reference :orders, :transmission, foreign_key: true
  end
end
