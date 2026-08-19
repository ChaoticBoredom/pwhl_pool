class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[ new create exchange ]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_session_path, alert: "Try again later." }

  def new
  end

  def create
    login_params = params.permit(
      :email_address,
      :password,
      session: [:email_address, :password]
    )

    email = login_params[:email_address] || login_params.dig(:session, :email_params)
    password = login_params[:password] || login_params.dig(:session, :password)
    if user = User.authenticate_by(email_address: email, password: password)
      start_new_session_for user
      render json: { data: { token: Current.session.token, user: user.id, god: user.admin } }
    else
      render json: {}, status: :unauthorized
    end
  end

  def exchange
    session = Session.find_by_exchange_code(params[:code])

    if session
      Current.session = session
      render json: { data: { token: session.token, user: session.user.id, god: session.user.admin } }
    else
      render json: {}, status: :unauthorized
    end
  end

  def destroy
    terminate_session
    render json: { message: "Logged out" }, status: :ok
  end
end
