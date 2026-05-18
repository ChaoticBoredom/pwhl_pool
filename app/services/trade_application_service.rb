class TradeApplicationService
  Player = Data.define(:id, :name)
  Result = Data.define(:added_players, :dropped_players)

  class TradeApplicationError < StandardError; end

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
        @pool_team.current_team.where(league_player_id: @dropping).each do |tp|
          tp.update!(dropped_at: @at)
        end
        dropped_players = players_for(@dropping)
      end

      if @adding.any?
        @adding.each do |pid|
          @pool_team.pool_team_players.create!(
            league_player_id: pid,
            added_at: @at,
            pool_box: box_by_player_id[pid],
          )
        end
        added_players = players_for(@adding)
      end
    end

    Result.new(added_players: added_players, dropped_players: dropped_players)
  end

  private

  def box_by_player_id
    @box_by_player_id ||= @pool.pool_boxes.each_with_object({}) do |pb, r_hash|
      pb.league_player_ids.each { |pid| r_hash[pid] = pb }
    end
  end

  def players_for(ids)
    League::Player.where(id: ids).pluck(:id, :name).map do |id, name|
      Player.new(id: id, name: name)
    end
  end
end
