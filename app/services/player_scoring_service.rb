class PlayerScoringService
  include DateFiltering

  def initialize(scorings)
    @calculator = ScoringCalculator.new(scorings)
  end

  def player_summaries(team_players, records)
    return {} if team_players.empty?

    team_players.each_with_object({}) do |tp, r_hash|
      player = tp.league_player
      player_records = records[tp.league_player_id] || []

      r_hash[tp.id] = {
        pool_score: calculate_aggregate(records_in_range(player_records, tp.active_range), player.roster_type),
        scores: build_scores_summary(player_records, player.roster_type),
        clipped_scores: build_scores_summary(player_records, player.roster_type, clip_range: tp.active_range),
      }
    end
  end

  def player_summary(team_player, records)
    player_summaries([team_player], records)[team_player.id]
  end

  def team_scores(pool_teams, records)
    return {} if pool_teams.empty?

    all_team_players = pool_teams.flat_map(&:pool_team_players)
    return {} if all_team_players.empty?

    team_totals = Hash.new(0.0)
    all_team_players.each do |tp|
      player_records = records[tp.league_player_id] || []
      clipped = records_in_range(player_records, tp.active_range)
      team_totals[tp.pool_team_id] += calculate_aggregate(clipped, tp.roster_type)
    end

    team_totals
  end

  def raw_player_summaries(players, records)
    return {} if players.empty?

    players.each_with_object({}) do |player, r_hash|
      player_records = records[player.id] || []
      r_hash[player.id] = build_scores_summary(player_records, player.roster_type)
    end
  end

  private

  def default_return
    0
  end

  def calculate_aggregate(records, roster_type)
    @calculator.calculate(records, roster_type)
  end

  # *_to_date intentionally exclude today, so we can add it and not recalculate
  # some values
  def build_scores_summary(records, roster_type, clip_range: nil)
    build_windowed_summary(records, roster_type, clip_range:) { |td, today| td + today }
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
    scorings.pluck(:roster_type, :field_name, :value).
      group_by { |row| row[0] }. # Group by roster_type
      transform_values { |rows| rows.map { |r| { field_name: r[1], value: r[2] } } }
  end

  def get_scoring_lookup
    @scorings.transform_values do |roster_type|
      roster_type.to_h { |s| [s[:field_name], s[:value]] }
    end
  end
end
