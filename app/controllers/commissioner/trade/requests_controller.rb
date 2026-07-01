class Commissioner::Trade::RequestsController < Commissioner::BaseController
  def index
    @trade_requests = @pool.
      trade_requests.
        includes(:league_player, :pool_box, :decided_by, pool_team: :owner).
        order(requested_at: :desc)

    @added_at_by_team_and_player = Pool::TeamPlayer.
      where(pool_team_id: @trade_requests.map(&:pool_team_id).uniq).
      where(dropped_at: nil).
      pluck(:pool_team_id, :league_player_id, :added_at).
      each_with_object({}) { |(team_id, player_id, added_at), h| h[[team_id, player_id]] = added_at }

    render :index
  end

  def update
    requests = @pool.trade_requests.trade_status_pending.where(id: params[:ids])

    if requests.count != Array(params[:ids]).count
      render json: { error: "One or more trade requests not found or not pending" }, status: :not_found
      return
    end

    backdated_to = params[:backdated_to].present? ? Time.zone.parse(params[:backdated_to]) : nil

    new_group_id = splitting_group?(requests) ? SecureRandom.uuid : nil

    case params[:status]
    when "approved"
      gids = []
      Trade::Request.transaction do
        requests.each do |r|
          r.update!(request_group_id: new_group_id) if new_group_id
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
  end

  private

  def splitting_group?(requests)
    # Multiple groups, keep their original group_request_ids
    requests.map(&:request_group_id).uniq.count == 1
  end
end
