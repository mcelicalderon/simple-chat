Rails.application.routes.draw do
  devise_for :users, controllers: {
    sessions:      'users/sessions',
    registrations: 'users/registrations',
    passwords:     'users/passwords',
    confirmations: 'users/confirmations'
  }

  root 'home#index'
  get '/test', to: 'home#test'
end
