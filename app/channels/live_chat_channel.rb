require "websocket-client-simple"

# Globals survive Rails code reloading — prevents duplicate relay threads after hot reload
$live_chat_relays ||= {}
$live_chat_relay_mutex ||= Mutex.new

class LiveChatChannel < ApplicationCable::Channel
  def self.stop_relay(account_id)
    $live_chat_relay_mutex.synchronize do
      relay = $live_chat_relays[account_id]
      return unless relay

      relay[:ws]&.close rescue nil
      relay[:thread]&.kill
      $live_chat_relays.delete(account_id)
    end
    Rails.logger.info("[LiveChatRelay] Stopped relay for account #{account_id}")
  end

  def subscribed
    account = current_user.account
    return reject unless account

    transmission = account.transmissions.find_by(id: params[:transmission_id], status: :active)
    return reject unless transmission

    stream_from "live_chat_#{account.id}"

    if relay_running?(account.id)
      $live_chat_relay_mutex.synchronize { $live_chat_relays[account.id][:transmission_id] = transmission.id }
    else
      start_relay(account, transmission.id)
    end
  end

  def unsubscribed
    # relay keeps running until transmission ends or live closes
  end

  private

  def relay_running?(account_id)
    $live_chat_relay_mutex.synchronize do
      $live_chat_relays[account_id]&.dig(:thread)&.alive?
    end
  end

  def start_relay(account, transmission_id)
    $live_chat_relay_mutex.synchronize do
      return if $live_chat_relays[account.id]&.dig(:thread)&.alive?

      thread = Thread.new do
        run_tiktok_relay(account.id)
      rescue => e
        Rails.logger.error("[LiveChatRelay] Thread error for account #{account.id}: #{e.message}")
      ensure
        $live_chat_relay_mutex.synchronize { $live_chat_relays.delete(account.id) }
      end

      $live_chat_relays[account.id] = { thread: thread, ws: nil, transmission_id: transmission_id }
    end
  end

  def run_tiktok_relay(account_id)
    account = Account.find(account_id)
    integration = account.integrations.find_by(provider: "tiktok", status: "active")
    return unless integration&.tiktok_username.present?

    euler_key = ENV["EULER_STREAM_API_KEY"]
    return unless euler_key.present?

    url = "wss://ws.eulerstream.com?uniqueId=#{integration.tiktok_username}&apiKey=#{euler_key}"
    Rails.logger.info("[LiveChatRelay] Connecting to EulerStream for @#{integration.tiktok_username}")

    closed = false
    ws = WebSocket::Client::Simple.connect(url)

    $live_chat_relay_mutex.synchronize { $live_chat_relays[account_id]&.merge!(ws: ws) }

    ws.on :message do |msg|
      next if msg.data.blank?
      begin
        payload = JSON.parse(msg.data)
        (payload["messages"] || []).each do |message|
          next unless message["type"] == "WebcastChatMessage"
          data = message["data"]

          current_tid = $live_chat_relay_mutex.synchronize { $live_chat_relays[account_id]&.dig(:transmission_id) }
          next unless current_tid

          sender_id = data.dig("user", "uniqueId") || ""
          platform_account = CustomerPlatformAccount.find_by(
            account_id: account_id,
            platform: "tiktok",
            platform_username: sender_id
          )

          payload_out = {
            platform:    "tiktok",
            sender_id:   sender_id,
            sender_name: data.dig("user", "nickname").presence || sender_id.presence || "?",
            body:        data["comment"],
            registered:  platform_account.present?,
            customer_id: platform_account&.customer_id
          }

          ActionCable.server.broadcast("live_chat_#{account_id}", payload_out)

          begin
            LiveChatMessage.create!(
              transmission_id: current_tid,
              platform:        :tiktok,
              sender_id:       payload_out[:sender_id],
              sender_name:     payload_out[:sender_name],
              body:            payload_out[:body]
            )
          rescue => e
            Rails.logger.error("[LiveChatRelay] Failed to persist message: #{e.message}")
          end
        end
      rescue JSON::ParserError
        # ignore malformed frames
      end
    end

    ws.on :close do |e|
      Rails.logger.info("[LiveChatRelay] Connection closed for account #{account_id}: #{e.inspect}")
      closed = true
    end

    ws.on :error do |e|
      Rails.logger.error("[LiveChatRelay] Error for account #{account_id}: #{e.message}")
      closed = true
    end

    sleep(0.1) until closed
  end
end
