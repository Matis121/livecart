class AllowNullForCheckoutTimestamps < ActiveRecord::Migration[8.0]
  def change
    change_column_null :checkouts, :expires_at, true
    change_column_null :checkouts, :completed_at, true
    change_column_null :checkouts, :last_viewed_at, true
  end
end
