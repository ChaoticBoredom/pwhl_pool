class Commissioner::Trade::RequestsController < Commissioner::BaseController
  before_action :load_requests, only: :update

  def index
    @trade_requests = @pool.
      trade_requests.
        includes(:league_player, :pool_box, :decided_by, pool_team: :owner).
        order(requested_at: :desc)

    @added_at_by_team_and_player = Pool::TeamPlayer.added_at_by_team_and_player(@trade_requests.map(&:pool_team_id).uniq)

    render :index
  end

  def update
    unless %w[approved rejected].include?(params[:status])
      render json: { error: "Invalid status: #{params[:status]}" }, status: :unprocessable_content
      return
    end

    Trade::RequestDecisionService.new(
      @requests,
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

  def load_requests
    @requests = @pool.trade_requests.trade_status_pending.where(id: params[:ids])

    if @requests.count != Array(params[:ids]).count
      render json: { error: "One or more trade requests not found or not pending" }, status: :not_found
    end
  end
end
