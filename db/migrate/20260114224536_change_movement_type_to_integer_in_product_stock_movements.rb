class ChangeMovementTypeToIntegerInProductStockMovements < ActiveRecord::Migration[8.0]
  def up
    # 1. Dodaj nową kolumnę
    add_column :product_stock_movements, :movement_type_int, :integer

    # 2. Przekonwertuj dane
    execute <<-SQL
      UPDATE product_stock_movements#{' '}
      SET movement_type_int = CASE movement_type
        WHEN 'sale' THEN 0
        WHEN 'restock' THEN 1
        ELSE 0
      END
    SQL

    # 3. Usuń starą, przemianuj nową
    remove_column :product_stock_movements, :movement_type
    rename_column :product_stock_movements, :movement_type_int, :movement_type

    # 4. Ustaw NOT NULL
    change_column_null :product_stock_movements, :movement_type, false
  end

  def down
    add_column :product_stock_movements, :movement_type_str, :string

    execute <<-SQL
      UPDATE product_stock_movements#{' '}
      SET movement_type_str = CASE movement_type
        WHEN 0 THEN 'sale'
        WHEN 1 THEN 'restock'
      END
    SQL

    remove_column :product_stock_movements, :movement_type
    rename_column :product_stock_movements, :movement_type_str, :movement_type
    change_column_null :product_stock_movements, :movement_type, false
  end
end
