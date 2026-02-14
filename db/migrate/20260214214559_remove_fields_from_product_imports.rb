class RemoveFieldsFromProductImports < ActiveRecord::Migration[8.0]
  def change
    remove_column :product_imports, :started_at, :datetime
    remove_column :product_imports, :completed_at, :datetime
  end
end
