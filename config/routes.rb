require "sidekiq/web"
require "sidekiq/cron/web"
require "rack/session/cookie"

secret_key_base = Rails.application.credentials.secret_key_base
Sidekiq::Web.use(Rack::Session::Cookie, secret: secret_key_base)
Rails.application.routes.draw do
  mount Sidekiq::Web => "/sidekiq"

  post '/users', to: 'users#create'
  resource :session
  resources :passwords, param: :token
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html
  #
  resources :pools do
    resources :pool_boxes, only: [:index]
  end
  resources :pool_teams, only: [:show, :create] do
    member do
      post :update_roster
    end
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"
end
