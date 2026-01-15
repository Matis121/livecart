class SimplifyOrderStatusHistory < ActiveRecord::Migration[8.0]
  def change
    remove_column :order_status_histories, :from_status
    rename_column :order_status_histories, :to_status, :status
  end
end