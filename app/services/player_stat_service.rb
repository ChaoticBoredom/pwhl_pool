class PlayerStatService
  include ScoringWindows

  def initialize(stats = nil)
    @stats = stats
  end

  def player_summaries(team_players, records)
    return {} if team_players.empty?

    team_players.each_with_object({}) do |tp, r_hash|
      player = tp.league_player
      player_records = records[tp.league_player_id] || []

      r_hash[tp.id] = {
        stats: build_stats_summary(player_records, player.roster_type),
        clipped_stats: build_stats_summary(
          player_records,
          player.roster_type,
          clip_range: tp.active_range),
      }
    end
  end

  def player_summary(team_player, records)
    player_summaries([team_player], records)[team_player.id]
  end

  private

  def calculate_aggregate(records, roster_type)
    return @stats[roster_type].to_h { |k| [k, 0] } if records.empty?

    @stats[roster_type].each_with_object({}) do |s, r_hash|
      r_hash[s] = records.sum { |r| parse_field(s, r[s]) }
    end
  end

  def default_return
    {}
  end

  def build_stats_summary(records, roster_type, clip_range: nil)
    build_windowed_summary(records, roster_type, clip_range:) { |td, today| td.merge(today) { |_, a, b| a + b } }
  end

  def parse_field(field, val)
    case val
    when true then 1
    when false then 0
    when ActiveSupport::Duration
      if field == :penalty_minutes
        val.in_minutes.to_i
      else
        val.in_seconds.to_i
      end
    else val.to_i
    end
  end
end
