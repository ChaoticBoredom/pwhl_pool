Rails.application.config.middleware.use OmniAuth::Builder do
  provider :google_oauth2,
    ENV.fetch("GOOGLE_CLIENT_ID", nil),
    ENV.fetch("GOOGLE_CLIENT_SECRET", nil)
end

OmniAuth.config.request_validation_phase = nil

OmniAuth.config.on_failure = Proc.new do |env|
  if env["omniauth.error.type"] == :access_denied
    OmniAuth::FailureEndpoint.new(env).redirect_to_failure
  else
    OmniAuth::FailureEndpoint.call(env)
  end
end
