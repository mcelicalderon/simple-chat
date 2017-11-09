class ChatChannel < ApplicationCable::Channel
  def subscribed
    stream_from 'sameroom'
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end

  def receive(data)
    broadcast_to('sameroom', data)
  end
end
