class HomeController < ApplicationController
  def index
    @users = User.where.not(id: current_user).order(:first_name, :last_name)
  end

  def test
    ActionCable.server.broadcast(
      "sameroom",
      sent_by: 'me',
      body: 'This is a cool chat app.'
    )
  end
end
