class CreateOrderStatusHistories < ActiveRecord::Migration[8.0]
  def change
    create_table :order_status_histories do |t|
      t.references :order, null: false, foreign_key: true
      t.integer :from_status
      t.integer :to_status, null: false

      t.timestamps
    end

    add_index :order_status_histories, :created_at
  end
end
