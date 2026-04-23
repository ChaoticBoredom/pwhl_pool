class PoolsController < ApplicationController
  def index
    @pools = Pool.
      where(id: current_user.pool_teams.pluck(:pool_id)).
      or(Pool.where(admin_id: current_user.id))
    render json: @pools
  end

  def show
    id = params[:id]
    @pool = Pool.
      includes(:admin, :scoring, pool_teams: :pool_team_players).
      find(id)

    pss = PlayerScoringService.new(@pool.scoring, @pool)

    @team_scores = pss.bulk_team_scores(@pool.pool_teams)

    render :show
  end
end
