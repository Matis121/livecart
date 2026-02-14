class ChangeDuplicateStrategyFromIntegerTostring < ActiveRecord::Migration[8.0]
  def change
    change_column :product_imports, :duplicate_strategy, :string, null: false, default: "import_all"
  end
end
