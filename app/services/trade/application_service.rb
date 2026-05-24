class Trade::ApplicationService
  Player = Data.define(:id, :name)
  Result = Data.define(:added_players, :dropped_players)

  class ApplicationError < StandardError; end

  def initialize(pool_team, adding:, dropping:, backdated_to: nil)
    @pool_team = pool_team
    @pool = pool_team.pool
    @adding = adding
    @dropping = dropping
    @at = backdated_to || Time.current
  end

  def self.from_approved_requests(requests)
    backdated_tos = requests.map(&:backdated_to).uniq
    raise ArgumentError, "Inconsistent backdated_to across group" if backdated_tos.count > 1

    drops, adds = requests.partition(&:trade_action_drop?)

    new(
      requests.first.pool_team,
      adding: adds.map(&:league_player_id),
      dropping: drops.map(&:league_player_id),
      backdated_to: requests.first.backdated_to,
    )
  end

  def call
    added_players = []
    dropped_players = []

    ActiveRecord::Base.transaction do
      if @dropping.any?
        actually_dropped = @pool_team.current_team.where(league_player_id: @dropping).map do |tp|
          tp.update!(dropped_at: @at)
          tp.league_player_id
        end
        dropped_players = players_for(actually_dropped)
      end

      if @adding.any?
        @adding.each do |pid|
          box = box_by_player_id[pid]
          raise ApplicationError, "No active box found for player #{pid}" unless box

          @pool_team.pool_team_players.create!(
            league_player_id: pid,
            added_at: @at,
            pool_box: box,
          )
        end
        added_players = players_for(@adding)
      end
    end

    Result.new(added_players: added_players, dropped_players: dropped_players)
  end

  private

  def box_by_player_id
    @box_by_player_id ||= @pool.active_box_by_player_id
  end

  def players_for(ids)
    League::Player.where(id: ids).pluck(:id, :name).map do |id, name|
      Player.new(id: id, name: name)
    end
  end
end
