class OmniauthCallbacksController < ApplicationController
  allow_unauthenticated_access only: %i[create failure]

  def create
    auth = request.env["omniauth.auth"]
    user = User.find_by(provider: auth.provider, uid: auth.uid) ||
      User.find_by(email_address: auth.info.email)

    if user
      user.update!(provider: auth.provider, uid: auth.uid) if user.provider.blank?
    else
      user = User.create!(
        email_address: auth.info.email,
        name: auth.info.name,
        password: SecureRandom.hex(32),
        provider: auth.provider,
        uid: auth.uid,
      )
    end

    session = start_new_session_for(user)
    code = Session.create_exchange_code_for(session)

    redirect_to "#{frontend_url}/auth/callback?code=#{code}", allow_other_host: true
  end

  def failure
    redirect_to "#{frontend_url}/login?error=oauth_failed", allow_other_host: true
  end

  private

  def frontend_url
    Rails.application.credentials.dig(:frontend_url) || "http://localhost:5173"
  end
end
