class CreateOrderFromTransmissionJob < ApplicationJob
  queue_as :default
  sidekiq_options retry: 3

  def perform(transmission_id, customer_id, transmission_item_ids)
    transmission = Transmission.find(transmission_id)
    customer = Customer.find(customer_id)
    items = TransmissionItem.where(id: transmission_item_ids).includes(:product)

    Rails.logger.info "📝📝📝 Creating order for Customer ##{customer_id} (#{customer.name}) with #{items.count} items"

    order = create_order(transmission, customer, items)

    if order.persisted?
      Rails.logger.info "✅✅✅ Order ##{order.id} created successfully for #{customer.name}"
    else
      Rails.logger.error "❌❌❌ Failed to create order for #{customer.name}: #{order.errors.full_messages.join(', ')}"
    end

  rescue StandardError => e
    Rails.logger.error "❌❌❌ Failed to create order for Customer ##{customer_id}: #{e.message}"
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
