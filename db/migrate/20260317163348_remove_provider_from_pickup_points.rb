class RemoveProviderFromPickupPoints < ActiveRecord::Migration[8.0]
  def change
    remove_column :pickup_points, :provider, :integer
  end
end
