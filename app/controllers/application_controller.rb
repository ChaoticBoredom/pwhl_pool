class ApplicationController < ActionController::API
  include ActionController::HttpAuthentication::Token::ControllerMethods
  include Authentication

  def current_user
    Current.user ||= Current.session&.user
  end

  # Only do this if you are strictly an API and understand the risks
  skip_before_action :verify_authenticity_token, raise: false
end
