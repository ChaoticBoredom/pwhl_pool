class PoolBoxesController < ApplicationController
  def index
    @pool = Pool.includes(:scoring).find(params[:pool_id])
    @boxes = Pool::Box.where(pool_id: @pool.id)

    current_pool_team = current_user&.pool_teams&.find_by(pool_id: @pool.id)
    @selected_ids = []
    if current_pool_team
      @selected_ids = current_pool_team.current_team.pluck(:league_player_id)
    end

    all_players = @boxes.flat_map(&:players).uniq(&:id)
    records = PlayerRecordQuery.new(all_players, season_id: @pool.display_season_id).records
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
    render json: { error: e.message }, status: :unprocessable_entity
  end

  private

  def build_config
    BoxGeneration::Config.new(
      teams: params[:teams]&.split(","),
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
        rank: b.fetch(:count, 0),
        count: b.fetch(:count, 0)
      )
    end
  end
end
