module Payments
  class PayuController < ApplicationController
    skip_before_action :authenticate_user!
    skip_before_action :verify_authenticity_token

    # POST /payments/payu/notify
    def notify
      raw_body = request.raw_post
      signature_header = request.headers["HTTP_OPENPAYU_SIGNATURE"] ||
                         request.headers["OpenPayu-Signature"]

      payload = JSON.parse(raw_body)
      payu_order_id = payload.dig("order", "orderId")

      unless payu_order_id.present?
        render json: { status: "ERROR", message: "Missing orderId" }, status: :bad_request
        return
      end

      order = Order.find_by(payu_order_id: payu_order_id)
      unless order
        # Return 200 — stop PayU retrying for an order that doesn't belong to us
        render json: { status: "OK" }, status: :ok
        return
      end

      integration = order.account.integrations.status_active.find_by(provider: "payu")
      unless integration
        Rails.logger.error("[PAYU] No active PayU integration for account #{order.account_id}")
        render json: { status: "ERROR", message: "Integration not found" }, status: :unprocessable_entity
        return
      end

      unless Integrations::Payu::IpnVerifier.valid?(
        raw_body: raw_body,
        signature_header: signature_header,
        md5key: integration.payu_md5key
      )
        Rails.logger.warn("[PAYU] IPN signature FAILED for PayU order #{payu_order_id}")
        render json: { status: "ERROR", message: "Invalid signature" }, status: :unauthorized
        return
      end

      process_notification(order, payload)
      render json: { status: "OK" }, status: :ok

    rescue JSON::ParserError => e
      Rails.logger.error("[PAYU] Invalid JSON in IPN: #{e.message}")
      render json: { status: "ERROR", message: "Invalid JSON" }, status: :bad_request
    rescue StandardError => e
      Rails.logger.error("[PAYU] Unexpected IPN error: #{e.class} - #{e.message}")
      render json: { status: "ERROR" }, status: :internal_server_error
    end

    private

    def process_notification(order, payload)
      payu_status = payload.dig("order", "status")
      Rails.logger.info("[PAYU] IPN for order #{order.order_number}: status=#{payu_status}")

      case payu_status
      when "COMPLETED"
        if order.payment_processing?
          order.update!(status: :paid, paid_amount: order.total_amount)
          checkout = order.checkout
          checkout.complete! if checkout && !checkout.completed?
          Rails.logger.info("[PAYU] Order #{order.order_number} marked as PAID")
        end
      when "CANCELED"
        if order.payment_processing?
          order.update!(status: :cancelled)
          Rails.logger.info("[PAYU] Order #{order.order_number} CANCELLED by PayU")
        end
      when "WAITING_FOR_CONFIRMATION"
        Rails.logger.info("[PAYU] Order #{order.order_number} waiting for manual confirmation")
      else
        Rails.logger.info("[PAYU] Unhandled status #{payu_status} for order #{order.order_number}")
      end
    end
  end
end
