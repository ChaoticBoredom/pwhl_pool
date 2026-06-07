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
      includes(:league, :admin, :scoring, pool_teams: [:owner, :pool_team_players]).
      find(id)

    records = PlayerRecordQuery.new(
      player_ids: Pool::TeamPlayer.where(pool: @pool).pluck(:league_player_id).uniq,
      season_id: @pool.season_id
    ).records

    pss = PlayerScoringService.new(@pool.scoring)

    @team_scores = pss.team_scores(@pool.pool_teams, records)
    @team_ranks = rank_teams(@team_scores)

    render :show
  end

  def meta
    render json: {
      leagues: League.all.map { |l| { id: l.id, name: l.name, short_name: l.short_name } },
      seasons: [
        { name: "2025-26 Regular Season", id: "8" },
        { name: "2025-26 Playoffs", id: "9" },
        # { name: "2026-27 Regular Season", id: "10" }
      ],
      pool_types: Pool.pool_types.keys,
      trade_policies: Pool.trade_policies.keys,
    }
  end

  def create
    @pool = Pool.new(pool_params.merge(admin: current_user))

    if @pool.save
      @pool.scoring.create(field_name: "goals", roster_type: "skater", value: 2)
      @pool.scoring.create(field_name: "assists", roster_type: "skater", value: 1)
      @pool.scoring.create(field_name: "hits", roster_type: "skater", value: 0.5)
      @pool.scoring.create(field_name: "saves", roster_type: "goalie", value: 0.05)
      @pool.scoring.create(field_name: "win", roster_type: "goalie", value: 2)
      @pool.scoring.create(field_name: "shutout", roster_type: "goalie", value: 5)
      render :show, status: :created
    else
      render json: { errors: @pool.errors.full_messages }, status: :unprocessable_content
    end
  end

  def update
    id = params[:id]
    @pool = Pool.find(id)

    if @pool.update(pool_name_params)
      render json: { message: "Pool Name updated!" }
    else
      render json: { errors: @pool.errors.full_messages }, status: :unprocessable_content
    end
  end

  private

  def pool_params
    params.require(:pool).permit(
      :name,
      :pool_type,
      :league_id,
      :season_id,
      :reference_season_id,
      :trade_policy,
    )
  end

  def pool_name_params
    params.require(:pool).permit(:name)
  end

  def rank_teams(team_scores)
    rankings = {}
    current_rank = 0
    last_score = nil

    team_scores.sort_by { |t, v| -v }.each.with_index(1) do |(tid, s), i|
      current_rank = i unless s == last_score

      rankings[tid] = current_rank

      last_score = s
    end

    # No score? Make sure we put them all as last
    rankings.default = current_rank + 1
    rankings
  end
end
