class ChatChannel < ApplicationCable::Channel
  def subscribed
    stream_from 'sameroom'
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end

  def receive(data)
    ActionCable.server.broadcast(
      "sameroom",
      sent_by: current_user.full_name,
      body: data['body'],
      timestamp: Time.now
    )
  end
end
