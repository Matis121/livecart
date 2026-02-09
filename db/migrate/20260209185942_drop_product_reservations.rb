class DropProductReservations < ActiveRecord::Migration[8.0]
  def change
    drop_table :product_reservations
  end
end
