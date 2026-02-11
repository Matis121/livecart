class AllowNullProductIdOnTransmissionItems < ActiveRecord::Migration[8.0]
  def change
    change_column_null :transmission_items, :product_id, true
  end
end
