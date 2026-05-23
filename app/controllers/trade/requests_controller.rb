class Trade::RequestsController < ApplicationController
  before_action :set_pool_team, :set_pool
  before_action :require_owner, only: [:create, :destroy]

  def index
    @trade_requests = @pool_team.
      trade_requests.
      order(requested_at: :desc)

    render :index
  end

  def create
    if @pool.trading_blocked?
      render json: {
        error: "Trades are currently locked for this pool",
        reason: "trades_closed",
      }, status: :forbidden
      return
    end

    if @pool.trading_allowed?
      @result = Trade::ApplicationService.new(@pool_team, adding: adding_ids, dropping: dropping_ids).call
      render :create
    elsif @pool.trading_allowed_pending_approval?
      service = Trade::RequestCreationService.new(@pool_team, current_user, adding: adding_ids, dropping: dropping_ids)

      if service.conflicts.any? && !params[:confirm_replace]
        @conflicts = service.conflicts
        render :conflicts, status: :conflict
        return
      end

      @group_id = params[:confirm_replace] ? service.call_replacing_conflicts : service.call
      render :queued, status: :created
    end
  rescue Trade::ApplicationService::ApplicationError,
       Trade::RequestCreationService::RequestCreationError => e
    render json: { error: e.message }, status: :unprocessable_content
  end

  def destroy
    @trade_request = @pool_team.trade_requests.trade_status_pending.find(params[:id])
    @trade_request.decide!(:cancelled,
      decided_by: current_user,
      decided_at: Time.current)
    head :no_content
  rescue ActiveRecord::RecordNotFound
    head :not_found
  end

  private

  def set_pool_team
    @pool_team = Pool::Team.find(params[:pool_team_id])
  end

  def set_pool
    @pool = @pool_team.pool
  end

  def require_owner
    head :forbidden unless current_user == @pool_team.owner
  end

  def original_player_ids
    @original_player_ids ||= @pool_team.current_team.pluck(:league_player_id)
  end

  def new_player_ids
    @new_player_ids ||= Array(params[:new_player_ids])
  end

  def adding_ids
    @adding_ids ||= new_player_ids - original_player_ids
  end

  def dropping_ids
    @dropping_ids ||= original_player_ids - new_player_ids
  end
end
