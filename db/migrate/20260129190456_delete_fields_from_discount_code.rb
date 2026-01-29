class DeleteFieldsFromDiscountCode < ActiveRecord::Migration[8.0]
  def change
    remove_column :discount_codes, :name
    remove_column :discount_codes, :description
    change_column_default :discount_codes, :value, from: nil, to: 0
  end
end
