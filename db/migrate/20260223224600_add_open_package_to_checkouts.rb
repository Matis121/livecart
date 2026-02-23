class AddOpenPackageToCheckouts < ActiveRecord::Migration[8.0]
  def change
    add_column :checkouts, :open_package, :boolean, default: false, null: false
    add_column :checkouts, :open_package_at, :datetime
  end
end
