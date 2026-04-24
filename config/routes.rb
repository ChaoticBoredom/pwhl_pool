require "sidekiq/web"
require "sidekiq/cron/web"
require "rack/session/cookie"

class AdminConstraint
  def matches?(request)
    return false unless request.session[:session_id]

    Session.find_by(id: request.session[:session_id]).user.admin?
  end
end

secret_key_base = Rails.application.credentials.secret_key_base
Sidekiq::Web.use(Rack::Session::Cookie, secret: secret_key_base)
Rails.application.routes.draw do
  constraints AdminConstraint.new do
    mount Sidekiq::Web => "/sidekiq"
  end

  scope :api, defaults: { format: :json } do
    post "/users", to: "users#create"
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

    get "/pool_teams/:pool_team_id/simple_show", to: "pool_teams#simple_show"
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  root to: "application#frontend"
  get "*path", to: "application#frontend", constraints: ->(request) { !request.xhr? && request.format.html? }
end
