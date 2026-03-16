class RemovePaidOrderStatus < ActiveRecord::Migration[8.0]
  def up
    # paid (3) → in_fulfillment (4)
    Order.where(status: 3).update_all(status: 4)
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
