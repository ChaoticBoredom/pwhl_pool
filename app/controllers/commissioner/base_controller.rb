class Commissioner::BaseController < ApplicationController
  before_action :require_pool
  before_action :require_commissioner
  rescue_from ActiveRecord::RecordInvalid, with: :render_invalid

  private

  def require_pool
    @pool = Pool.includes(pool_includes).find(params[:pool_id] || params[:id])
  rescue ActiveRecord::RecordNotFound
    head :not_found
  end

  def pool_includes
    []
  end

  def require_commissioner
    head :forbidden unless current_user == @pool.admin || current_user&.admin?
  end

  def render_invalid(exception)
    render json: { errors: exception.message }, status: :unprocessable_content
  end
end
