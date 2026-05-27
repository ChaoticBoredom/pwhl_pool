class Commissioner::BaseController < ApplicationController
  before_action :require_pool
  before_action :require_commissioner

  private

  def require_pool
    @pool = Pool.find(params[:pool_id])
  rescue ActiveRecord::RecordNotFound
    head :not_found
  end

  def require_commissioner
    head :forbidden unless current_user == @pool.admin || current_user&.admin?
  end
end
