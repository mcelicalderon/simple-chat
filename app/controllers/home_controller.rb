class HomeController < ApplicationController
  def index
  end

  def test
    ActionCable.server.broadcast(
      "some_channel",
      sent_by: 'me',
      body: 'This is a cool chat app.'
    )
  end
end
