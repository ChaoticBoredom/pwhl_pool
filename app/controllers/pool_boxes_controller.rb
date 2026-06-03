class PoolBoxesController < ApplicationController
  def index
    @pool = Pool.includes(:scoring).find(params[:pool_id])
    @boxes = @pool.pool_boxes.active

    target_team = if params[:pool_team_id]
      @pool.pool_teams.find(params[:pool_team_id])
    else
      current_user&.pool_teams&.find_by(pool_id: @pool.id)
    end

    @selected_ids = target_team&.current_team&.pluck(:league_player_id) || []
    @has_pending_trades = target_team&.trade_requests&.trade_status_pending&.any? || false

    all_players = @boxes.flat_map(&:players).uniq(&:id)
    records = PlayerRecordQuery.new(players: all_players, season_id: @pool.display_season_id).records
    pss = PlayerScoringService.new(@pool.scoring)

    @player_scores = pss.raw_player_summaries(all_players, records)

    render :index
  end

  def generate
    @pool = Pool.includes(:scoring, :league).find(params[:pool_id])

    config = build_config
    @result = BoxGenerationService.new(@pool, config, season_id: params[:season_id].presence).call
    render :generate
  rescue BoxGenerationService::BoxGenerationError => e
    render json: { error: e.message }, status: :unprocessable_content
  end

  private

  def build_config
    BoxGeneration::Config.new(
      teams: params[:teams],
      scope: params[:scope],
      boxes: build_boxes,
      excluded_player_ids: params[:excluded_player_ids] || []
    )
  end

  def build_boxes
    return BoxGeneration::DEFAULT_BOXES unless params[:boxes].present?

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
end
