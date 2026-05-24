class Commissioner::Trade::RequestsController < Commissioner::BaseController
  before_action :set_trade_request, only: [:update]

  def index
    @trade_requests = @pool.trade_requests.order(requested_at: :desc)
    render :index
  end

  def update
    case params[:status]
    when "approved"
      backdated_to = params[:backdated_to].present? ? Time.zone.parse(params[:backdated_to]) : nil

      Trade::Request.transaction do
        @trade_request.decide!(
          :approved,
          decided_by: current_user,
          decided_at: Time.current,
          backdated_to: backdated_to,
        )

        TradeApprovalWorker.perform_async(@trade_request.request_group_id)
      end

      redner json: { message: "Trade request approved" }, status: :ok
    when "rejected"
      @trade_request.decide!(
        :rejected,
        decided_by: current_user,
        decided_at: Time.current,
        rejected_reason: params[:rejected_reason],
      )

      render json: { message: "Trade request rejected" }, status: :ok
    else
      render json: { error: "Invalid status: #{params[:status]}" }, status: :unprocessable_content
    end
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: e.message }, status: :unprocessable_content
  end

  private

  def set_trade_request
    @trade_request = @pool.trade_requests.trade_status_pending.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    head :not_found
  end
end
