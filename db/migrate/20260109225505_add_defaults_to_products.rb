class AddDefaultsToProducts < ActiveRecord::Migration[8.0]
  def change
    change_column_default :products, :gross_price, from: nil, to: 0.00
    change_column_default :products, :tax_rate, from: nil, to: 23
    change_column_default :products, :quantity, from: nil, to: 0
    change_column_default :products, :currency, from: nil, to: "PLN"
  end
end
