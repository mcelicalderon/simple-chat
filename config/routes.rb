Rails.application.routes.draw do
  root 'home#index'
  get '/test', to: 'home#test'
end
