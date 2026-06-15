class Commissioner::PoolBoxesController < Commissioner::BaseController
  def index
    boxes = @pool.pool_boxes.active.order(:position)

    all_player_ids = boxes.flat_map(&:league_player_ids).uniq
    all_players = League::Player.
      where(id: all_player_ids)

    records = PlayerRecordQuery.new(player_ids: all_players, season_id: @pool.display_season_id).records
    pss = PlayerScoringService.new(@pool.scoring)
    player_scores = pss.raw_player_summaries(all_players, records)
    players_by_id = all_players.index_by(&:id)

    @result = boxes.map do |box|
      {
        name: box.name,
        position: box.position,
        players: box.league_player_ids.map do |id|
          player = players_by_id[id]
          {
            id: id,
            name: player.name,
            current_team_short_code: player.current_team_short_code,
            position: player.position,
            rookie: player.rookie?,
            score: player_scores.dig(id, :scores, :season_to_date) || 0,
          }
        end,
      }
    end
    @free_agents = compute_free_agents(@result)

    render :generate
  end

  def default
    scoring_version = @pool.scoring.maximum(:updated_at).to_i
    cache_key = "pool_boxes/default/#{@pool.cache_key_with_version}/#{scoring_version}"

    result = Rails.cache.fetch(cache_key, expires_in: 3.hours) do
      boxes = BoxGenerationService.new(@pool, BoxGeneration::Config.new(
        boxes: @pool.league.stat_config::DEFAULT_BOXES
      )).call
      free_agents = compute_free_agents(boxes)
      { boxes: boxes, free_agents: free_agents }
    end

    @result = result[:boxes]
    @free_agents = result[:free_agents]
    render :generate
  rescue BoxGenerationService::BoxGenerationError => e
    render json: { error: e.message }, status: :unprocessable_content
  end

  def generate
    @pool = Pool.includes(:scoring, :league).find(params[:pool_id])

    config = build_config
    @result = BoxGenerationService.new(@pool, config, season_id: params[:season_id].presence).call

    @free_agents = compute_free_agents(@result)
    render :generate
  rescue BoxGenerationService::BoxGenerationError => e
    render json: { error: e.message }, status: :unprocessable_content
  end

  def create
    result = BoxReplacementService.new(@pool, boxes_params).call

    if result.success
      render json: { boxes: @pool.pool_boxes.reload.active }, status: :created
    else
      render json: { errors: result.errors }, status: :unprocessable_content
    end
  end

  alias_method :update, :create

  private

  def boxes_params
    params.require(:boxes).map do |box|
      box.permit(:name, :position, players: [:id])
    end
  end

  def build_config
    BoxGeneration::Config.new(
      teams: params[:teams],
      scope: params[:scope],
      boxes: build_boxes,
      excluded_player_ids: params[:excluded_player_ids] || []
    )
  end

  def build_boxes
    return @pool.league.stat_config::DEFAULT_BOXES unless params[:boxes].present?

    params[:boxes].map do |b|
      BoxGeneration::BoxDefinition.new(
        name: b[:name],
        position: b[:position],
        rookie: b[:rookie],
        rank: b.fetch(:rank, 1),
        count: b.fetch(:count, 1)
      )
    end
  end

  def compute_free_agents(boxes)
    assigned_ids = boxes.flat_map { |v| v[:players].map { |p| p[:id] } }

    free_agent_players = League::Player.
      active.
      where(league: @pool.league).
      where.not(id: assigned_ids)

    records = PlayerRecordQuery.new(
      players: free_agent_players,
      season_id: @pool.display_season_id,
    ).records

    pss = PlayerScoringService.new(@pool.scoring)
    summaries = pss.raw_player_summaries(free_agent_players, records)

    free_agent_players.map do |player|
      {
        id: player.id,
        name: player.name,
        current_team_short_code: player.current_team_short_code,
        score: summaries.dig(player.id, :scores, :season_to_date) || 0,
        position: player.position,
        rookie: player.rookie?,
      }
    end.sort_by { |p| -p[:score] }
  end
end
