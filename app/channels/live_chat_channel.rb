class LiveChatChannel < ApplicationCable::Channel
  def subscribed
    transmission = current_user.account.transmissions.find_by(id: params[:transmission_id])

    if transmission.nil?
      reject
    else
      stream_from "live_chat_transmission_#{transmission.id}"
    end
  end

  def unsubscribed
    stop_all_streams
  end
end
