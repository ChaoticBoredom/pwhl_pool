class Trade::RequestDecisionService
  class RequestDecisionError < StandardError; end

  def initialize(requests, status:, decided_by:, backdated_to: nil, rejected_reason: nil)
    @requests = requests
    @status = status
    @decided_by = decided_by
    @backdated_to = backdated_to.presence && Time.zone.parse(backdated_to)
    @rejected_reason = rejected_reason
  end

  def call
    if status == "approved"
      raise RequestDecisionError, backdate_error if backdated_to && backdate_error

      approve!
    else
      reject!
    end
  end

  private

  attr_reader :requests, :status, :decided_by, :backdated_to, :rejected_reason

  def new_group_id
    @new_group_id ||= splitting_group?(requests) ? SecureRandom.uuid : nil
  end

  def approve!
    gids = []

    Trade::Request.transaction do
      requests.each do |r|
        r.update!(request_group_id: new_group_id) if new_group_id
        r.decide!(
          :approved,
          decided_by: decided_by,
          decided_at: Time.current,
          backdated_to: backdated_to,
        )
        gids << r.request_group_id
      end
    end

    gids.uniq.each { |gid| TradeApprovalWorker.perform_async(gid) }
  end

  def reject!
    raise RequestDecisionError, "Rejection reason is required" if rejected_reason.blank?

    Trade::Request.transaction do
      requests.each do |r|
        r.update!(request_group_id: new_group_id) if new_group_id
        r.decide!(
          :rejected,
          decided_by: decided_by,
          decided_at: Time.current,
          rejected_reason: rejected_reason,
        )
      end
    end
  end

  def splitting_group?(requests)
    requests.map(&:request_group_id).uniq.count == 1
  end

  def backdate_error
    drop_requests = requests.select(&:trade_action_drop?)
    return nil if drop_requests.empty?

    lookup = Pool::TeamPlayer.added_at_by_team_and_player(drop_requests.map(&:pool_team_id).uniq)

    violations = drop_requests.filter_map do |r|
      added_at = lookup[[r.pool_team_id, r.league_player_id]]
      next unless added_at && backdated_to.to_date < added_at.to_date

      "#{r.league_player.name} (added #{added_at.to_date})"
    end

    return nil if violations.empty?

    "Cannot backdate to #{backdated_to.to_date} — invalid for: #{violations.join(", ")}"
  end
end
