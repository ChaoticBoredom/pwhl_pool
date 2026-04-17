class UsersController < ApplicationController
	allow_unauthenticated_access only: :create

  def create
    @user = User.new(user_params)

    if @user.save
      start_new_session_for @user

      render json: {
        data: {
          user: @user.id,
          token: Current.session.token,
        }
      }, status: :created
    else
      render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def user_params
    params.permit(:name, :email_address, :password)
  end
end
