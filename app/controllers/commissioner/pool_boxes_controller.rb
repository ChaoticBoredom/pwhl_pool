class Commissioner::PoolBoxesController < Commissioner::BaseController
  def generate
    @pool = Pool.includes(:scoring, :league).find(params[:pool_id])

    config = build_config
    @result = BoxGenerationService.new(@pool, config, season_id: params[:season_id].presence).call
    render :generate
  rescue BoxGenerationService::BoxGenerationError => e
    render json: { error: e.message }, status: :unprocessable_content
  end

  def create
    result = BoxReplacementService.new(@pool, boxes_params).call

    if result.success
      render json: { boxes: @pool.pool_boxes.reload.active }, status: :created
    else
      render json: { errors: result.errors }, status: :unprocessable_entity
    end
  end

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
