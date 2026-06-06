class Commissioner::PoolsController < Commissioner::BaseController
  def update
    if @pool.update(pool_update_params)
      render :show
    else
      render json: { errors: @pool.errors.full_messages }, status: :unprocessable_content
    end
  end

  def activate
    unless @pool.pool_state_draft?
      return render json: { error: "Pool must be in draft state to activate" }, status: :unprocessable_entity
    end

    unless @pool.pool_boxes.active.any?
      return render json: { error: "Pool must have at least one active box before activating" }, status: :unprocessable_entity
    end

    @pool.pool_state_active!
    render json: { state: @pool.state }
  end

  private

  def pool_update_params
    params.require(:pool).permit(:name, :trade_policy, :reference_season_id)
  end

  def pool_includes
    { pool_teams: :owner }
  end
end
