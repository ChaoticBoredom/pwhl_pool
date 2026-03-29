class PoolsController < ApplicationController
  def show
    id = params.extract_value(:id)
    @pool = Pool.includes(:pool_teams).find(id)
    render json: @pool,
      only: [:name, :pool_type],
      include: {
        league: { only: [:id, :name, :short_name] },
        admin: { only: [:id, :name] },
        pool_teams: {
          include: { user: { only: [:id, :name] } },
          only: [:id, :team_name] },
      }
  end
end
