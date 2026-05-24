require "sidekiq/web"
require "sidekiq/cron/web"
require "rack/session/cookie"

Sidekiq::Web.use Rack::Auth::Basic do |username, password|
  ActiveSupport::SecurityUtils.secure_compare(username, ENV.fetch("SIDEKIQ_USERNAME", "admin")) &
  ActiveSupport::SecurityUtils.secure_compare(password, ENV.fetch("SIDEKIQ_PASSWORD", "password"))
end

secret_key_base = Rails.application.credentials.secret_key_base
Sidekiq::Web.use(Rack::Session::Cookie, secret: secret_key_base)
Rails.application.routes.draw do
  mount Sidekiq::Web => "/sidekiq"

  scope :api, defaults: { format: :json } do
    post "/users", to: "users#create"
    resource :session
    resources :passwords, param: :token
    # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html
    #
    resources :league_games, path: "games", only: [:show]
    resources :league_players, path: "players", only: [] do
      member do
        get :team_player
      end
    end
    resources :pools do
      resources :pool_boxes, only: [:index] do
        collection do
          post :generate
        end
      end
      resources :pool_scoring, only: [:index]
    end
    resources :pool_teams, only: [:show, :create, :update] do
      member do
        post :update_roster
      end
      resources :trade_requests, only: [:create, :index, :destroy], controller: "trade/requests"
    end

    namespace :commissioner do
      resources :pools, only: [] do
        resources :trade_requests, only: [:index], controller: "trade/requests" do
          collection do
            patch :update
          end
        end
      end
    end
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  root to: "application#frontend"
  get "*path", to: "application#frontend", constraints: ->(request) { !request.xhr? && request.format.html? }
end
