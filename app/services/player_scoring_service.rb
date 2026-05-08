class PlayerScoringService
  include DateFiltering

  def initialize(scorings)
    @scorings = format_scorings(scorings)
    @scoring_lookup = get_scoring_lookup.with_indifferent_access
  end

  def player_summaries(team_players, records)
    return {} if team_players.empty?

    team_players.each_with_object({}) do |tp, r_hash|
      player = tp.league_player
      player_records = records[tp.league_player_id] || []

      r_hash[tp.id] = {
        pool_score: calculate_aggregate(records_in_range(player_records, tp.active_range), player.position),
        scores: build_scores_summary(player_records, player.position),
        clipped_scores: build_scores_summary(player_records, player.position, clip_range: tp.active_range),
      }
    end
  end

  def player_summary(team_player, records)
    player = team_player.league_player
    player_records = records[player.id]

    {
      pool_score: calculate_aggregate(records_in_range(player_records, team_player.active_range), player.position),
      scores: build_scores_summary(player_records, player.position),
      clipped_scores: build_scores_summary(player_records, player.position, clip_range: team_player.active_range),
    }
  end

  def team_scores(pool_teams, records)
    return {} if pool_teams.empty?

    all_team_players = pool_teams.flat_map(&:pool_team_players)
    return {} if all_team_players.empty?

    team_totals = Hash.new(0.0)
    all_team_players.each do |tp|
      player_records = records[tp.league_player_id] || []
      clipped = records_in_range(player_records, tp.active_range)
      team_totals[tp.pool_team_id] += calculate_aggregate(clipped, tp.position)
    end

    team_totals
  end

  def raw_player_summaries(players, records)
    return {} if players.empty?

    players.each_with_object({}) do |player, r_hash|
      player_records = records[player.id] || []
      r_hash[player.id] = build_scores_summary(player_records, player.position)
    end
  end

  def calculate_scores_across_hash(stats, position)
    stats.each_with_object({}) do |(key, val), r_hash|
      r_hash[key] = if val.is_a?(Hash)
        calculate_scores_across_hash(val, position)
      else
        if @scoring_lookup[position].key?(key)
          parse_field(val) * @scoring_lookup[position][key]
        else
          0
        end
      end
    end
  end

  private

  def default_return
    0
  end

  def calculate_aggregate(records, position)
    return default_return if records.empty?

    scoring_fields = @scorings[position]
    return 0 if scoring_fields.nil?

    scoring_fields.sum do |s|
      records.sum { |r| parse_field(r[s[:field_name]]) } * s[:value]
    end
  end

  # *_to_date intentionally exclude today, so we can add it and not recalculate
  # some values
  def build_scores_summary(records, position, clip_range: nil)
    today = score_window(records, position, Time.current.all_day, clip_range:)
    yesterday = score_window(records, position, 1.day.ago.all_day, clip_range:)
    week_to_date = score_window(records, position, week_to_date_range, clip_range:)
    month_to_date = score_window(records, position, month_to_date_range, clip_range:)
    season_to_date = score_window(records, position, season_to_date_range, clip_range:)

    {
      today: today,
      yesterday: yesterday,
      week_to_date: week_to_date + today,
      month_to_date: month_to_date + today,
      season_to_date: season_to_date + today,
    }
  end

  def parse_field(val)
    case val
    when true then 1
    when false then 0
    when ActiveSupport::Duration then val.in_minutes.to_i
    else val.to_i
    end
  end

  def format_scorings(scorings)
    scorings.pluck(:position, :field_name, :value).
      group_by { |row| row[0] }. # Group by position
      transform_values { |rows| rows.map { |r| { field_name: r[1], value: r[2] } } }
  end

  def get_scoring_lookup
    @scorings.transform_values do |position|
      position.to_h { |s| [s[:field_name], s[:value]] }
    end
  end
end
