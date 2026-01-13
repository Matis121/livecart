class CreateProductReservations < ActiveRecord::Migration[8.0]
  def change
    create_table :product_reservations do |t|
      t.references :product, null: false, foreign_key: true
      t.references :order, null: false, foreign_key: true
      t.references :order_item, null: false, foreign_key: true
      t.integer :quantity, null: false
      t.string :status, null: false, default: "pending"
      t.string :reservation_type, null: false, default: "order"

      t.timestamps
    end
  end
end
