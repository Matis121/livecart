class TransmissionConverterJob < ApplicationJob
  queue_as :default

  def perform(transmission_id)
    transmission = Transmission.find(transmission_id)

    # Zmień status na processing
    transmission.update!(status: :processing)

    Rails.logger.info "🚀🚀🚀 Starting transmission conversion for Transmission ##{transmission_id}"

    # Grupuj po customer_id - każdy klient dostanie jedno zamówienie
    customer_items_map = transmission.transmission_items
                                 .includes(:customer, :product)
                                 .group_by(&:customer_id)

    Rails.logger.info "📊📊📊 Creating #{customer_items_map.size} orders for #{customer_items_map.size} customers"

    customer_items_map.each do |customer_id, items|
      CreateOrderFromTransmissionJob.perform_later(
        transmission_id,
        customer_id,
        items.map(&:id)
      )
    end

    transmission.update!(status: :completed)


  rescue StandardError => e
    Rails.logger.error "❌❌❌ Failed to start transmission conversion: #{e.message}"
    transmission.update(status: :active) # przywróć status
    raise e
  end
end
