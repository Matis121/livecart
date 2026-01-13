class DeleteReservationTypeFromProductReservations < ActiveRecord::Migration[8.0]
  def change
    remove_column :product_reservations, :reservation_type, :string
  end
end
