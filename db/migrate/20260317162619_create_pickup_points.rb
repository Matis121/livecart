class CreatePickupPoints < ActiveRecord::Migration[8.0]
  def change
    create_table :pickup_points do |t|
      t.references :order, null: false, foreign_key: true
      t.string :point_id
      t.string :name
      t.string :address_line1
      t.string :postal_code
      t.string :city
      t.integer :provider

      t.timestamps
    end
  end
end
