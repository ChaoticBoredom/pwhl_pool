class PoolsController < ApplicationController
  def index
    @pools = if current_user.admin?
      Pool.all
    else
      Pool.
        where(id: current_user.pool_teams.pluck(:pool_id)).
        or(Pool.where(admin_id: current_user.id))
    end
    @current_user_id = current_user.id
    @season_labels = Pwhl::StatConfig::SEASON_LABELS

    render :index
  end

  def show
    id = params[:id]
    @pool = Pool.
      includes(:league, :admin, :scoring, :pool_boxes, pool_teams: [:owner, :pool_team_players]).
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
      seasons: Pwhl::StatConfig::SEASON_LABELS.map { |k, v| { id: k, name: v } },
      pool_types: Pool.pool_types.keys.map { |k| { value: k, label: k.to_s.titleize } },
      trade_policies: Pool.trade_policies.keys.map { |k| { value: k, label: k.to_s.titleize } },
    }
  end

  def create
    @pool = Pool.new(pool_params.merge(admin: current_user))

    if @pool.save
      render :show, status: :created
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
