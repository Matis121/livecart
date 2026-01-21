# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Znajdź lub stwórz konto
account = Account.first_or_create!(
  company_name: "Test Company",
  nip: "1234567890"
)

puts "Account created: #{account.company_name}"

# Kategorie produktów do generowania
product_categories = [
  "Laptop", "Monitor", "Klawiatura", "Mysz", "Słuchawki",
  "Telefon", "Tablet", "Smartwatch", "Kamera", "Drukarka",
  "Router", "Dysk SSD", "Pamięć RAM", "Karta graficzna", "Procesor",
  "Zasilacz", "Obudowa PC", "Chłodzenie", "Pendrive", "Powerbank"
]

tax_rates = [ 0, 5, 8, 23 ]
currencies = [ "PLN", "EUR", "USD" ]

puts "Tworzenie 100 produktów..."

100.times do |i|
  category = product_categories.sample

  product = Product.create!(
    account: account,
    name: "#{category} #{i + 1}",
    ean: "590#{rand(1000000000000..9999999999999)}",
    sku: "SKU-#{category.upcase.gsub(' ', '-')}-#{1000 + i}",
    tax_rate: tax_rates.sample,
    gross_price: rand(50.0..5000.0).round(2),
    currency: currencies.sample,
    quantity: rand(0..100)
  )

  # Stwórz stock dla produktu
  ProductStock.create!(
    product: product,
    quantity: rand(0..200),
    sync_enabled: [ true, false ].sample,
    last_synced_at: rand(1..30).days.ago
  )

  print "." if (i + 1) % 10 == 0
end

puts "\n✓ Utworzono 100 produktów!"
puts "Całkowita liczba produktów: #{Product.count}"
