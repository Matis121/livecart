class AddSlugToAccounts < ActiveRecord::Migration[8.0]
  def up
    add_column :accounts, :slug, :string

    # Backfill slugs from company_name
    Account.reset_column_information
    Account.find_each do |account|
      base_slug = account.company_name.to_s.parameterize
      base_slug = "shop-#{account.id}" if base_slug.blank?
      slug = base_slug
      counter = 1
      while Account.where(slug: slug).where.not(id: account.id).exists?
        slug = "#{base_slug}-#{counter}"
        counter += 1
      end
      account.update_column(:slug, slug)
    end

    change_column_null :accounts, :slug, false
    add_index :accounts, :slug, unique: true
    add_index :accounts, :company_name, unique: true
  end

  def down
    remove_index :accounts, :company_name
    remove_index :accounts, :slug
    remove_column :accounts, :slug
  end
end
