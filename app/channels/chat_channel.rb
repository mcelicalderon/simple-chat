class ChatChannel < ApplicationCable::Channel
  def subscribed
    stream_from "user_#{current_user.id}"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end

  def receive(data)
    ActionCable.server.broadcast(
      "user_#{to_user_id(data)}",
      message_data(data)
    )
  end

  private

  def message_data(data)
    {
      sent_by: current_user.id,
      sent_by_full_name: current_user.full_name,
      body: data['body'],
      timestamp: Time.zone.now
    }
  end

  def to_user_id(data)
    data['to_user_id']
  end
end
