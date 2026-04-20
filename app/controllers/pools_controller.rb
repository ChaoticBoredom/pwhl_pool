class PoolsController < ApplicationController
  def index
    @pools = Pool.where(id: current_user.pool_teams.pluck(:pool_id)).
      or(Pool.where(admin_id: current_user.id))
    render json: @pools
  end

  def show
    id = params[:id]
    @pool = Pool.includes(:pool_teams).find(id)
    render json: @pool,
      only: [:name, :pool_type],
      include: {
        league: { only: [:id, :name, :short_name] },
        admin: { only: [:id, :name] },
        pool_teams: {
          include: { user: { only: [:id, :name] } },
          only: [:id, :team_name],
          methods: [:total_score],
        },
      }
  end
end
