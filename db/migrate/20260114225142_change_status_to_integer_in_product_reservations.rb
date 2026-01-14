class ChangeStatusToIntegerInProductReservations < ActiveRecord::Migration[8.0]
  def up
    add_column :product_reservations, :status_int, :integer

    execute <<-SQL
      UPDATE product_reservations#{' '}
      SET status_int = CASE status
        WHEN 'pending' THEN 0
        WHEN 'completed' THEN 1
        WHEN 'cancelled' THEN 2
        ELSE 0
      END
    SQL

    remove_column :product_reservations, :status
    rename_column :product_reservations, :status_int, :status

    change_column_null :product_reservations, :status, false
    change_column_default :product_reservations, :status, 0
  end

  def down
    add_column :product_reservations, :status_str, :string

    execute <<-SQL
      UPDATE product_reservations#{' '}
      SET status_str = CASE status
        WHEN 0 THEN 'pending'
        WHEN 1 THEN 'completed'
        WHEN 2 THEN 'cancelled'
      END
    SQL

    remove_column :product_reservations, :status
    rename_column :product_reservations, :status_str, :status

    change_column_null :product_reservations, :status, false
    change_column_default :product_reservations, :status, 'pending'
  end
end
