class AddDiscountNameToOrder < ActiveRecord::Migration[8.0]
  def change
    add_column :orders, :discount_name, :string
  end
end
