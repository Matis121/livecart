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

ActiveRecord::Schema[8.0].define(version: 2026_01_14_225142) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "accounts", force: :cascade do |t|
    t.string "company_name", null: false
    t.string "nip", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
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

  create_table "order_items", force: :cascade do |t|
    t.bigint "order_id", null: false
    t.bigint "product_id"
    t.string "name", null: false
    t.string "ean", null: false
    t.string "sku", null: false
    t.decimal "unit_price", null: false
    t.integer "quantity", null: false
    t.decimal "total_price", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["order_id"], name: "index_order_items_on_order_id"
    t.index ["product_id"], name: "index_order_items_on_product_id"
  end

  create_table "orders", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.bigint "customer_id"
    t.string "order_number", null: false
    t.string "order_token", null: false
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
    t.index ["account_id"], name: "index_orders_on_account_id"
    t.index ["customer_id"], name: "index_orders_on_customer_id"
  end

  create_table "product_reservations", force: :cascade do |t|
    t.bigint "product_id", null: false
    t.bigint "order_id", null: false
    t.bigint "order_item_id", null: false
    t.integer "quantity", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "status", default: 0, null: false
    t.index ["order_id"], name: "index_product_reservations_on_order_id"
    t.index ["order_item_id"], name: "index_product_reservations_on_order_item_id"
    t.index ["product_id"], name: "index_product_reservations_on_product_id"
  end

  create_table "product_stock_movements", force: :cascade do |t|
    t.bigint "product_id", null: false
    t.bigint "order_item_id", null: false
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
    t.index ["account_id"], name: "index_products_on_account_id"
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

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "account_id"
    t.index ["account_id"], name: "index_users_on_account_id"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "billing_addresses", "orders"
  add_foreign_key "customers", "accounts"
  add_foreign_key "order_items", "orders"
  add_foreign_key "order_items", "products"
  add_foreign_key "orders", "accounts"
  add_foreign_key "orders", "customers"
  add_foreign_key "product_reservations", "order_items"
  add_foreign_key "product_reservations", "orders"
  add_foreign_key "product_reservations", "products"
  add_foreign_key "product_stock_movements", "order_items"
  add_foreign_key "product_stock_movements", "products"
  add_foreign_key "product_stocks", "products"
  add_foreign_key "products", "accounts"
  add_foreign_key "shipping_addresses", "orders"
  add_foreign_key "users", "accounts"
end
