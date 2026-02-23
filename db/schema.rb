# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2026_02_23_155342) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "accounts", force: :cascade do |t|
    t.string "company_name", null: false
    t.string "nip", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "checkout_settings"
    t.jsonb "terms"
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "billing_addresses", force: :cascade do |t|
    t.bigint "order_id", null: false
    t.boolean "needs_invoice"
    t.string "company_name"
    t.string "nip"
    t.string "first_name"
    t.string "last_name"
    t.string "address_line1"
    t.string "address_line2"
    t.string "city"
    t.string "postal_code"
    t.string "country"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["order_id"], name: "index_billing_addresses_on_order_id"
  end

  create_table "checkouts", force: :cascade do |t|
    t.bigint "order_id", null: false
    t.string "token", null: false
    t.datetime "expires_at"
    t.datetime "completed_at"
    t.integer "activation_hours", default: 24, null: false
    t.integer "views_count", default: 0, null: false
    t.datetime "last_viewed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "active", default: false, null: false
    t.index ["expires_at"], name: "index_checkouts_on_expires_at"
    t.index ["order_id"], name: "index_checkouts_on_order_id"
    t.index ["token"], name: "index_checkouts_on_token", unique: true
  end

  create_table "customers", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.string "platform_user_id"
    t.string "platform"
    t.string "platform_username"
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.json "profile_data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_customers_on_account_id"
  end

  create_table "discount_codes", force: :cascade do |t|
    t.string "code", null: false
    t.integer "kind", default: 0, null: false
    t.decimal "value", precision: 8, scale: 2, default: "0.0", null: false
    t.decimal "minimum_order_amount", precision: 8, scale: 2
    t.boolean "free_shipping", default: false
    t.datetime "valid_from"
    t.datetime "valid_until"
    t.integer "usage_limit"
    t.integer "used_count", default: 0
    t.boolean "active", default: false
    t.bigint "account_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_discount_codes_on_account_id"
    t.index ["code"], name: "index_discount_codes_on_code"
  end

  create_table "integration_exports", force: :cascade do |t|
    t.bigint "order_id", null: false
    t.bigint "integration_id", null: false
    t.string "external_id"
    t.datetime "exported_at"
    t.integer "status", default: 0, null: false
    t.text "error_message"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["integration_id"], name: "index_integration_exports_on_integration_id"
    t.index ["order_id", "integration_id"], name: "index_integration_exports_on_order_id_and_integration_id", unique: true
    t.index ["order_id"], name: "index_integration_exports_on_order_id"
  end

  create_table "integrations", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "provider", null: false
    t.string "provider_uid"
    t.string "provider_account_name"
    t.text "access_token"
    t.text "refresh_token"
    t.datetime "token_expires_at"
    t.string "api_key"
    t.string "api_secret"
    t.jsonb "settings", default: {}, null: false
    t.jsonb "metadata", default: {}, null: false
    t.string "status", default: "active", null: false
    t.datetime "last_synced_at"
    t.text "last_error_message"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "account_id", null: false
    t.integer "integration_type", default: 0, null: false
    t.index ["account_id", "provider"], name: "index_integrations_on_account_and_provider", unique: true
    t.index ["account_id"], name: "index_integrations_on_account_id"
    t.index ["integration_type"], name: "index_integrations_on_integration_type"
    t.index ["provider"], name: "index_integrations_on_provider"
    t.index ["provider_uid"], name: "index_integrations_on_provider_uid"
    t.index ["status"], name: "index_integrations_on_status"
    t.index ["user_id"], name: "index_integrations_on_user_id"
  end

  create_table "order_items", force: :cascade do |t|
    t.bigint "order_id", null: false
    t.bigint "product_id"
    t.string "name", null: false
    t.string "ean"
    t.string "sku"
    t.decimal "unit_price", null: false
    t.integer "quantity", null: false
    t.decimal "total_price", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["order_id"], name: "index_order_items_on_order_id"
    t.index ["product_id"], name: "index_order_items_on_product_id"
  end

  create_table "order_status_histories", force: :cascade do |t|
    t.bigint "order_id", null: false
    t.integer "status", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_order_status_histories_on_created_at"
    t.index ["order_id"], name: "index_order_status_histories_on_order_id"
  end

  create_table "orders", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.bigint "customer_id"
    t.string "order_number", null: false
    t.string "email"
    t.string "phone"
    t.decimal "total_amount", null: false
    t.decimal "shipping_cost", default: "0.0", null: false
    t.string "currency", default: "PLN", null: false
    t.string "shipping_method"
    t.text "comment"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "payment_method"
    t.decimal "paid_amount", default: "0.0", null: false
    t.integer "status", default: 0, null: false
    t.bigint "discount_code_id"
    t.decimal "discount_amount", precision: 8, scale: 2, default: "0.0", null: false
    t.string "discount_name"
    t.bigint "transmission_id"
    t.index ["account_id"], name: "index_orders_on_account_id"
    t.index ["customer_id"], name: "index_orders_on_customer_id"
    t.index ["discount_code_id"], name: "index_orders_on_discount_code_id"
    t.index ["transmission_id"], name: "index_orders_on_transmission_id"
  end

  create_table "product_imports", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.string "import_name", null: false
    t.integer "status", default: 0, null: false
    t.string "duplicate_strategy", default: "import_all", null: false
    t.integer "total_rows", default: 0
    t.integer "success_count", default: 0
    t.integer "skipped_count", default: 0
    t.integer "error_count", default: 0
    t.text "error_details"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id", "created_at"], name: "index_product_imports_on_account_id_and_created_at"
    t.index ["account_id"], name: "index_product_imports_on_account_id"
    t.index ["status"], name: "index_product_imports_on_status"
  end

  create_table "product_stock_movements", force: :cascade do |t|
    t.bigint "product_id", null: false
    t.bigint "order_item_id"
    t.integer "quantity_change", null: false
    t.integer "quantity_before", null: false
    t.integer "quantity_after", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "movement_type", null: false
    t.index ["order_item_id"], name: "index_product_stock_movements_on_order_item_id"
    t.index ["product_id"], name: "index_product_stock_movements_on_product_id"
  end

  create_table "product_stocks", force: :cascade do |t|
    t.bigint "product_id", null: false
    t.integer "quantity", default: 0, null: false
    t.datetime "last_synced_at"
    t.boolean "sync_enabled", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["product_id"], name: "index_product_stocks_on_product_id"
  end

  create_table "products", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.string "name"
    t.string "ean"
    t.string "sku"
    t.integer "tax_rate", default: 23
    t.decimal "gross_price", default: "0.0"
    t.integer "quantity", default: 0
    t.string "currency", default: "PLN"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "baselinker_product_id"
    t.index ["account_id"], name: "index_products_on_account_id"
    t.index ["baselinker_product_id"], name: "index_products_on_baselinker_product_id"
  end

  create_table "shipping_addresses", force: :cascade do |t|
    t.bigint "order_id", null: false
    t.string "first_name"
    t.string "last_name"
    t.string "address_line1"
    t.string "address_line2"
    t.string "city"
    t.string "postal_code"
    t.string "country"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["order_id"], name: "index_shipping_addresses_on_order_id"
  end

  create_table "shipping_methods", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.string "name", null: false
    t.decimal "price", precision: 8, scale: 2
    t.decimal "free_above", precision: 8, scale: 2
    t.boolean "is_pickup_point", default: false
    t.integer "pickup_point_provider"
    t.integer "position", default: 0
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_shipping_methods_on_account_id"
  end

  create_table "transmission_items", force: :cascade do |t|
    t.bigint "transmission_id", null: false
    t.bigint "customer_id", null: false
    t.bigint "product_id"
    t.string "name", null: false
    t.string "ean"
    t.string "sku"
    t.decimal "unit_price", precision: 8, scale: 2, default: "0.0", null: false
    t.integer "quantity", default: 1, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["customer_id"], name: "index_transmission_items_on_customer_id"
    t.index ["product_id"], name: "index_transmission_items_on_product_id"
    t.index ["transmission_id"], name: "index_transmission_items_on_transmission_id"
  end

  create_table "transmissions", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.integer "status", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name", null: false
    t.index ["account_id"], name: "index_transmissions_on_account_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "account_id"
    t.integer "role", default: 1, null: false
    t.index ["account_id"], name: "index_users_on_account_id"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "billing_addresses", "orders"
  add_foreign_key "checkouts", "orders"
  add_foreign_key "customers", "accounts"
  add_foreign_key "discount_codes", "accounts"
  add_foreign_key "integration_exports", "integrations"
  add_foreign_key "integration_exports", "orders"
  add_foreign_key "integrations", "accounts"
  add_foreign_key "integrations", "users"
  add_foreign_key "order_items", "orders"
  add_foreign_key "order_items", "products"
  add_foreign_key "order_status_histories", "orders"
  add_foreign_key "orders", "accounts"
  add_foreign_key "orders", "customers"
  add_foreign_key "orders", "discount_codes"
  add_foreign_key "orders", "transmissions"
  add_foreign_key "product_imports", "accounts"
  add_foreign_key "product_stock_movements", "order_items"
  add_foreign_key "product_stock_movements", "products"
  add_foreign_key "product_stocks", "products"
  add_foreign_key "products", "accounts"
  add_foreign_key "shipping_addresses", "orders"
  add_foreign_key "shipping_methods", "accounts"
  add_foreign_key "transmission_items", "customers"
  add_foreign_key "transmission_items", "products"
  add_foreign_key "transmission_items", "transmissions"
  add_foreign_key "transmissions", "accounts"
  add_foreign_key "users", "accounts"
end
