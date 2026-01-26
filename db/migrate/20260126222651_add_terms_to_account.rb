class AddTermsToAccount < ActiveRecord::Migration[8.0]
  def change
    add_column :accounts, :terms, :jsonb
  end
end
