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
