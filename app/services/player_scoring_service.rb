class PlayerScoringService
  def initialize(scorings, pool)
    @scorings = format_scorings(scorings)
    @pool = pool
  end

  def scores_for_players_for_season(players)
    player_ids = players.map(&:league_player_id)
    skater_stats = Pwhl::SkaterStat
      .joins(:league_game)
      .where(league_player_id: player_ids)
      .where(league_games: { season_id: @pool.season_id })
      .group_by(&:league_player_id)

    goalie_stats = Pwhl::GoalieStat
      .joins(:league_game)
      .where(league_player_id: player_ids)
      .where(league_games: { season_id: @pool.season_id })
      .group_by(&:league_player_id)

    players.each_with_object({}) do |player, result|
      stats = player.is_a?(Pwhl::Goalie) ? goalie_stats : skater_stats
      date_range = player.clip_date_range(@pool.start_end_range)
      records = (stats[player.id] || []).select { |r| date_range.cover?(r.league_game.start_time) }
      result[player.id] = calculate_aggregate(records, player)
    end
  end

  def score_for_team_player(team_player)
    date_range = team_player.clip_date_range(@pool.start_end_range)
    score_for_date_range(date_range, team_player.league_player)
  end

  def score_for_today(player)
    score_for_date(Time.current, player)
  end

  def score_for_yesterday(player)
    score_for_date(1.day.ago, player)
  end

  def score_for_season(player)
    score_for_date_range(@pool.start_end_range, player)
  end

  # The following '_to_date' methods do not include todays scoring
  def score_for_week_to_date(player)
    score_for_date_range(Time.current.beginning_of_week..1.day.ago.end_of_day, player)
  end

  def score_for_month_to_date(player)
    score_for_date_range(Time.current.beginning_of_month..1.day.ago.end_of_day, player)
  end

  def score_for_season_to_date(player)
    start = @pool.start_end_range.begin
    score_for_date_range(start..1.day.ago.end_of_day, player)
  end

  def score_for_date(date, player)
    target_date = date.to_date
    record = player.records.for_date(target_date)
    calculate_aggregate(record, player)
  end

  def score_for_date_range(date_range, player)
    date_range = date_range.begin.beginning_of_day..date_range.end.end_of_day
    records = player.records.for_season(@pool.season_id).for_date_range(date_range)
    calculate_aggregate(records, player)
  end

  def scores_summary(player)
    to_date_scores = {
      season_to_date: score_for_season_to_date(player),
      month_to_date: score_for_month_to_date(player),
      week_to_date: score_for_week_to_date(player),
    }
    todays_score = score_for_today(player)

    to_date_scores.
      transform_values { |v| v + todays_score }.
      merge({
        yesterday: score_for_yesterday(player),
        today: todays_score,
      })
  end

  def player_scorings_cache_key
    Digest::MD5.hexdigest(@scorings.to_json)
  end

  private

  def calculate_aggregate(record, player)
    return 0 if record.nil?

    scoring_fields = @scorings[player.position]
    return 0 if scoring_fields.nil?

    fields = scoring_fields.pluck(:field_name)
    records = Array(record)

    scoring_fields.sum do |s|
      records.sum { |r| parse_field(r[s[:field_name]]) } * s[:value]
    end
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
      group_by { |a| a[0] }.
      transform_values { |b| b.map { |c| { field_name: c[1], value: c[2] } } }
  end
end
