class CreateTransmissions < ActiveRecord::Migration[8.0]
  def change
    create_table :transmissions do |t|
      t.references :account, null: false, foreign_key: true
      t.integer :status, null: false, default: 0

      t.timestamps
    end
  end
end
