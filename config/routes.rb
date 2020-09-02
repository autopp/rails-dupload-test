Rails.application.routes.draw do
  namespace :api do
    resources :direct_uploads, only: [:create]
  end
  resources :users
  root to: 'home#index'
end
