class RemoveStatusFromCheckout < ActiveRecord::Migration[8.0]
  def change
    remove_column :checkouts, :status
    add_column :checkouts, :active, :boolean, null: false, default: false
  end
end
