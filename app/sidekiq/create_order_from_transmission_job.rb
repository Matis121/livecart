class CreateOrderFromTransmissionJob < ApplicationJob
  queue_as :default
  sidekiq_options retry: 3

  def perform(transmission_id, customer_id, transmission_item_ids)
    transmission = Transmission.find(transmission_id)
    customer = Customer.find(customer_id)
    items = TransmissionItem.where(id: transmission_item_ids).includes(:product)

    Rails.logger.info "📝📝📝 Creating order for Customer ##{customer_id} (#{customer.name}) with #{items.count} items"

    # Sprawdź czy klient ma otwartą paczkę (tylko gdy funkcja jest włączona)
    existing_order = if transmission.account.open_package_enabled?
      Order.open_package_for_customer(customer, transmission.account).first
    end

    if existing_order
      Rails.logger.info "📦 Found open package Order ##{existing_order.id} for #{customer.name} — adding items"
      existing_order.add_transmission_items!(items, transmission)
      Rails.logger.info "✅ Added #{items.count} items to existing Order ##{existing_order.id} for #{customer.name}"
    else
      order = create_order(transmission, customer, items)

      if order.persisted?
        Rails.logger.info "✅ Order ##{order.id} created successfully for #{customer.name}"
      else
        Rails.logger.error "❌ Failed to create order for #{customer.name}: #{order.errors.full_messages.join(', ')}"
      end
    end

  rescue StandardError => e
    Rails.logger.error "❌ Failed to create order for Customer ##{customer_id}: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    raise e # Sidekiq retry
  end

  private

  def create_order(transmission, customer, items)
    Order.transaction do
      order = Order.create!(
        account: transmission.account,
        customer: customer,
        status: :draft,
        total_amount: 0,
        shipping_cost: 0,
        currency: "PLN",
        transmission: transmission,
        email: customer.email.presence,
        phone: customer.phone.presence,
      )

      items.each do |item|
        order.order_items.create!(
          product_id: item.product_id,
          name: item.name,
          ean: item.ean,
          sku: item.sku,
          unit_price: item.unit_price || 0,
          quantity: item.quantity,
        )
      end

      order
    end
  end
end
