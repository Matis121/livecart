class AddNameToTransmissions < ActiveRecord::Migration[8.0]
  def change
    add_column :transmissions, :name, :string, null: false
  end
end
