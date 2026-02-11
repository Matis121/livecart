class AllowNullEanAndSkuOnOrderItems < ActiveRecord::Migration[8.0]
  def change
    change_column_null :order_items, :ean, true
    change_column_null :order_items, :sku, true
  end
end
