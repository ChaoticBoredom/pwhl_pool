class God::BaseController < ApplicationController
  before_action :require_god

  private

  def require_god
    head :forbidden unless current_user&.admin?
  end
end
