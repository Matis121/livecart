class AddLiveFieldsToTransmissions < ActiveRecord::Migration[8.0]
  def change
    add_reference :transmissions, :integration, foreign_key: true, null: true
    add_column :transmissions, :live_external_id, :string
    add_column :transmissions, :live_room_id, :string
    add_index :transmissions, :live_external_id
  end
end
