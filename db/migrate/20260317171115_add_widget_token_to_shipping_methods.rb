class AddWidgetTokenToShippingMethods < ActiveRecord::Migration[8.0]
  def change
    add_column :shipping_methods, :widget_token, :string
  end
end
