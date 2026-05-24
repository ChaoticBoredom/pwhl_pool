class Commissioner::Trade::RequestsController < Commissioner::BaseController
  def index
    @trade_requests = @pool.trade_requests.order(requested_at: :desc)
    render :index
  end

  def update
    requests = @pool.trade_requests.trade_status_pending.where(id: params[:ids])

    if requests.count != Array(params[:ids]).count
      render json: { error: "One or more trade requests not found or not pending" }, status: :not_found
      return
    end

    backdated_to = params[:backdated_to].present? ? Time.zone.parse(params[:backdated_to]) : nil

    effective_group_id = effective_group_id?(requests, backdated_to)

    case params[:status]
    when "approved"
      gids = []
      Trade::Request.transaction do
        requests.each do |r|
          r.update!(request_group_id: effective_group_id) unless effective_group_id.nil?
          r.decide!(
            :approved,
            decided_by: current_user,
            decided_at: Time.current,
            backdated_to: backdated_to,
          )
          gids << r.request_group_id
        end
      end

      gids.uniq.each { |gid| TradeApprovalWorker.perform_async(gid) }

      render json: { message: "Trade request approved" }, status: :ok
    when "rejected"
      Trade::Request.transaction do
        requests.each do |r|
          r.decide!(
            :rejected,
            decided_by: current_user,
            decided_at: Time.current,
            rejected_reason: params[:rejected_reason],
          )
        end
      end

      render json: { message: "Trade request rejected" }, status: :ok
    else
      render json: { error: "Invalid status: #{params[:status]}" }, status: :unprocessable_content
    end
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: e.message }, status: :unprocessable_content
  end

  private

  def effective_group_id?(requests, backdated_to)
    return nil if backdated_to.nil?
    # Multiple groups, keep their original group_request_ids
    return nil if requests.map(&:request_group_id).uniq.count > 1

    SecureRandom.uuid
  end
end
