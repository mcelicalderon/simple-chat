class ApplicationController < ActionController::Base
  before_action :authenticate_user!
  protect_from_forgery with: :exception, prepend: true

  private

  def after_sign_out_path_for(resource_or_scope)
    url_for(controller: 'sessions', action: :new)
  end
end
