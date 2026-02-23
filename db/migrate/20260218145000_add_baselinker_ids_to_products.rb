class AddBaselinkerIdsToProducts < ActiveRecord::Migration[8.0]
  def change
    add_column :products, :baselinker_product_id, :string
    add_index :products, :baselinker_product_id
  end
end
