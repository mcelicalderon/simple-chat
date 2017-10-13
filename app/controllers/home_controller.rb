class HomeController < ApplicationController
  def index
  end

  def test
    ActionCable.server.broadcast(
      "sameroom",
      sent_by: 'me',
      body: 'This is a cool chat app.'
    )
  end
end
