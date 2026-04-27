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
    @team_ranks = rank_teams(@team_scores)

    render :show
  end

  def update
    id = params[:id]
    @pool = Pool.find(id)

    if @pool.update(pool_name_params)
      render json: { message: "Pool Name updated!" }
    else
      render json: { errors: @pool.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def pool_name_params
    params.require(:pool).permit(:name)
  end

  def rank_teams(team_scores)
    ordered_scores = team_scores.values.sort.reverse
    rankings = team_scores.to_a.inject({}) do |h, (tid, score)|
      h[tid] = (ordered_scores.index(score) + 1).ordinalize
      h
    end

    # No score? Make sure we put them all as last
    rankings.default = (team_scores.size + 1).ordinalize
    rankings
  end
end
