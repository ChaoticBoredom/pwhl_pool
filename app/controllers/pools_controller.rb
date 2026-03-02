class PoolsController < ApplicationController
  def show
    id = params.extract_value(:id)
    @pool = Pool.find(id)
    render json: @pool,
      only: [:name, :pool_type],
      include: { 
        league: { only: [:name, :short_name] },
        admin: { only: [:name] },
        pool_teams: { 
          include: { user: { only: [:name] } }, 
          only: [:team_name] }
      }
  end
end
