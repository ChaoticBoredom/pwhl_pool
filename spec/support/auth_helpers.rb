module AuthHelpers
  def auth_headers_for(user)
    session = user.sessions.create!(
      user_agent: "RSpec Test",
      ip_address: "127.0.0.1"
    )

    {
      "Authorization" => "Bearer #{session.token}",
      "Content-Type" => "application/json",
    }
  end
end
