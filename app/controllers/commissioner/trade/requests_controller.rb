class Commissioner::Trade::RequestsController < Commissioner::BaseController
  def index
    @trade_requests = @pool.
      trade_requests.
        includes(:league_player, :pool_box, :decided_by, pool_team: :owner).
        order(requested_at: :desc)

    @added_at_by_team_and_player = Pool::TeamPlayer.
      added_at_by_team_and_player(@trade_requests.map(&:pool_team_id).uniq)

    render :index
  end

  def update
    unless %w[approved rejected].include?(params[:status])
      render json: { error: "Invalid status: #{params[:status]}" }, status: :unprocessable_content
      return
    end

    Trade::RequestDecisionService.new(
      @pool,
      ids: params[:ids],
      status: params[:status],
      decided_by: current_user,
      backdated_to: params[:backdated_to],
      rejected_reason: params[:rejected_reason],
    ).call

    render json: { message: "Trade request #{params[:status]}" }, status: :ok
  rescue Trade::RequestDecisionService::RequestDecisionError => e
    render json: { error: e.message }, status: :unprocessable_content
  end

  private

  def splitting_group?(requests)
    # Multiple groups, keep their original group_request_ids
    requests.map(&:request_group_id).uniq.count == 1
  end
end
