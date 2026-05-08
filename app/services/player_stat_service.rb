class PlayerStatService
  include DateFiltering

  STATS = {
    goalie: [
      :goals, :assists, :goals_against, :shots_against, :penalty_minutes,
      :win, :shutout, :saves, :time_on_ice, :game_started
    ],
    skater: [
      :goals, :assists, :penalty_minutes, :shots, :hits, :time_on_ice,
      :plus_minus, :power_play_goals, :short_handed_goals, :shots_blocked,
      :faceoffs_taken, :faceoffs_won, :game_winning_goals
    ],
  }.with_indifferent_access.freeze

  def player_summaries(team_players, records)
    return {} if team_players.empty?

    team_players.each_with_object({}) do |tp, r_hash|
      player = tp.league_player
      player_records = records[tp.league_player_id] || []

      r_hash[tp.id] = {
        stats: build_stats_summary(player_records, player.position),
        clipped_stats: build_stats_summary(
          player_records,
          player.position,
          clip_range: tp.active_range),
      }
    end
  end

  def player_summary(team_player, records)
    player_summaries([team_player], records)[team_player.league_player_id]
  end

  private

  def stat_classes
    [Pwhl::SkaterStat, Pwhl::GoalieStat]
  end

  def calculate_aggregate(records, position)
    return STATS[position].to_h { |k| [k, 0] } if records.empty?

    STATS[position].each_with_object({}) do |s, r_hash|
      r_hash[s] = records.sum { |r| parse_field(s, r[s]) }
    end
  end

  def default_return
    {}
  end

  def build_stats_summary(records, position, clip_range: nil)
    today = score_window(records, position, Time.current.all_day, clip_range:)
    yesterday = score_window(records, position, 1.day.ago.all_day, clip_range:)
    week_to_date = score_window(records, position, week_to_date_range, clip_range:)
    month_to_date = score_window(records, position, month_to_date_range, clip_range:)
    season_to_date = score_window(records, position, season_to_date_range, clip_range:)

    {
      today: today,
      yesterday: yesterday,
      week_to_date: week_to_date.merge(today) { |_, td, t| td + t },
      month_to_date: month_to_date.merge(today) { |_, td, t| td + t },
      season_to_date: season_to_date.merge(today) { |_, td, t| td + t },
    }
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
