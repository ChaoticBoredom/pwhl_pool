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

    @box_counts = Pool::Box.active.where(pool: @pools).group(:pool_id).count
    @scoring_counts = Pool::Scoring.where(pool: @pools).group(:pool_id).count

    render :index
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
      seasons: Pwhl::StatConfig::SEASON_LABELS.map { |k, v| { id: k, name: v } },
      pool_types: Pool.pool_types.keys,
      trade_policies: Pool.trade_policies.keys,
    }
  end

  def create
    @pool = Pool.new(pool_params.merge(admin: current_user))

    if @pool.save
      seed_default_scoring
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

  def seed_default_scoring
    stat_config = @pool.league.stat_config
    stat_config::DEFAULT_SCORING.each do |roster_type, fields|
      fields.each do |field_name, value|
        @pool.scoring.create!(
          field_name: field_name,
          roster_type: roster_type,
          value: value,
        )
      end
    end
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
