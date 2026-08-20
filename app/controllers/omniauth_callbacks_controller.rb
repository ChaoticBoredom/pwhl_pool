class OmniauthCallbacksController < ApplicationController
  allow_unauthenticated_access only: %i[create failure]

  def create
    user = find_or_create_user(request.env["omniauth.auth"])
    session = start_new_session_for(user)
    code = Session.create_exchange_code_for(session)

    redirect_to "#{frontend_url}/auth/callback?code=#{code}", allow_other_host: true
  end

  def failure
    redirect_to "#{frontend_url}/login?error=oauth_failed", allow_other_host: true
  end

  private

  def find_or_create_user(auth)
    user = User.find_by(provider: auth.provider, uid: auth.uid) ||
      User.find_by(email_address: auth.info.email)

    if user
      user.update!(provider: auth.provider, uid: auth.uid) if user.provider.blank?
      user
    else
      User.create!(
        email_address: auth.info.email,
        name: auth.info.name,
        password: SecureRandom.hex(32),
        provider: auth.provider,
        uid: auth.uid,
      )
    end
  end

  def frontend_url
    ENV.fetch("FRONTEND_URL", "http://localhost:5173")
  end
end
