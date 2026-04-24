class ApplicationController < ActionController::API
  include ActionView::Layouts
  include ActionController::Rendering
  include ActionController::HttpAuthentication::Token::ControllerMethods
  include Authentication

  skip_before_action :require_authentication, only: [:frontend], raise: false

  def current_user
    Current.user ||= Current.session&.user
  end

  def frontend
    render file: Rails.root.join("public", "index.html"), layout: false
  end

  # Only do this if you are strictly an API and understand the risks
  skip_before_action :verify_authenticity_token, raise: false
end
