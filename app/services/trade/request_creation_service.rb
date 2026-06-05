class Trade::RequestCreationService
  class RequestCreationError < StandardError; end

  def initialize(pool_team, requested_by, adding:, dropping:)
    @pool_team = pool_team
    @pool = pool_team.pool
    @requested_by = requested_by
    @adding = adding
    @dropping = dropping
  end

  def conflicts
    @conflicts ||= Trade::Request.trade_status_pending.where(
      pool_team: @pool_team,
      league_player_id: @adding + @dropping
    ).includes(:league_player)
  end

  def call
    create_requests(SecureRandom.uuid)
  end

  def call_replacing_conflicts
    group_id = SecureRandom.uuid
    Trade::Request.transaction do
      conflicts.each do |r|
        r.decide!(:cancelled,
          decided_by: @requested_by,
          decided_at: Time.current)
      end
      create_requests(group_id)
    end
    group_id
  rescue ActiveRecord::RecordInvalid => e
    raise RequestCreationError, e.message
  end

  private

  def create_requests(group_id)
    Trade::Request.transaction do
      @dropping.each do |player_id|
        tp = @pool_team.current_team.find_by(league_player_id: player_id)
        create_request!(
          player_id: player_id,
          pool_box: tp&.pool_box,
          action: :drop,
          group_id: group_id
        )
      end

      @adding.each do |player_id|
        box = box_by_player_id[player_id]
        raise RequestCreationError, "No active box found for player #{player_id}" unless box
        create_request!(
          player_id: player_id,
          pool_box: box,
          action: :add,
          group_id: group_id,
        )
      end
    end

    group_id
  rescue ActiveRecord::RecordInvalid => e
    raise RequestCreationError, e.message
  rescue ActiveRecord::RecordNotUnique
    raise RequestCreationError, "A confliction trade request already exists"
  end

  def create_request!(player_id:, pool_box:, action:, group_id:)
    Trade::Request.create!(
      pool_team: @pool_team,
      requested_by: @requested_by,
      league_player_id: player_id,
      pool_box: pool_box,
      action: action,
      status: :pending,
      requested_at: Time.current,
      request_group_id: group_id,
    )
  end

  def box_by_player_id
    @box_by_player_id ||= @pool.active_box_by_player_id
  end
end
