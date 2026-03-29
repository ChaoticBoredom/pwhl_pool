class PoolTeamsController < ApplicationController
  def show
    id = params.extract_value(:id)
    @pool_team = Pool::Team.find(id)
    render json: @pool_team
  end
end
