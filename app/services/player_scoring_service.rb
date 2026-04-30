class PlayerScoringService
  def initialize(scorings, pool)
    @scorings = format_scorings(scorings)
    @pool = pool
  end

  def player_summaries(team_players)
    return {} if team_players.empty?

    records_map = load_season_records_for(team_players.map(&:league_player_id))

    team_players.each_with_object({}) do |tp, r_hash|
      player = tp.league_player
      records = records_map[tp.league_player_id] || []
      active_range = player_active_range(tp)

      r_hash[tp.id] = {
        pool_score: season_score_from_records(records, player.position, active_range),
        scores: build_scores_summary(records, player.position),
        clipped_scores: build_scores_summary(records, player.position, clip_range: active_range),
      }
    end
  end

  def player_summary(team_player)
    player = team_player.league_player
    records = load_player_season_records(player)
    active_range = player_active_range(team_player)

    {
      pool_score: season_score_from_records(records, player.position, active_range),
      scores: build_scores_summary(records, player.position),
      clipped_scores: build_scores_summary(records, player.position, clip_range: active_range),
    }
  end

  def bulk_team_scores(pool_teams)
    return {} if pool_teams.empty?

    all_team_players = pool_teams.flat_map(&:pool_team_players)
    return {} if all_team_players.empty?

    records_map = load_season_records_for(all_team_players.map(&:league_player_id))

    team_totals = Hash.new(0.0)
    all_team_players.each do |tp|
      records = records_map[tp.league_player_id] || []
      active_range = player_active_range(tp)
      clipped = records_in_range(records, active_range)
      team_totals[tp.pool_team_id] += calculate_aggregate(clipped, tp.position)
    end

    team_totals
  end

  def raw_player_summaries(players)
    return {} if players.empty?

    records_map = load_season_records_for(players.map(&:id))

    players.each_with_object({}) do |player, r_hash|
      records = records_map[player.id] || []
      r_hash[player.id] = build_scores_summary(records, player.position)
    end
  end

  def raw_player_season_totals(players, season_id: nil)
    return {} if players.empty?

    effective_season = season_id || @pool.display_season_id
    records_map = load_season_records_for(players.map(&:id), season_id: effective_season)

    players.each_with_object({}) do |player, r_hash|
      records = records_map[player.id] || []
      r_hash[player.id] = calculate_aggregate(records, player.position)
    end
  end

  private

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

  def season_score_from_records(records, position, active_range)
    calculate_aggregate(records_in_range(records, active_range), position)
  end

  def score_window(records, position, window, clip_range: nil)
    effective_range = clip_range ? intersect_ranges(window, clip_range) : window
    return 0 unless effective_range

    calculate_aggregate(records_in_range(records, effective_range), position)
  end

  def load_player_season_records(player)
    player.
      records.
      for_season(@pool.season_id).
      includes(:league_game).
      to_a
  end

  def load_season_records_for(player_ids, season_id: @pool.season_id)
    records = [Pwhl::SkaterStat, Pwhl::GoalieStat].flat_map do |klass|
      klass.
        includes(:league_game).
        joins(:league_game).
        where(league_player_id: player_ids).
        where(league_games: { season_id: season_id }).
        to_a
    end.group_by(&:league_player_id)
  end

  def player_active_range(team_player)
    season_end = @pool.start_end_range.end
    effective_end = [season_end, team_player.dropped_at].compact.min

    team_player.added_at..effective_end
  end

  def records_in_range(records, range)
    records.select { |r| range.cover?(r.league_game.start_time) }
  end

  def intersect_ranges(a, b)
    start = [a.begin, b.begin].max
    stop = [a.end, b.end].min
    start <= stop ? start..stop : nil
  end

  def calculate_aggregate(records, position)
    return 0 if records.empty?

    scoring_fields = @scorings[position]
    return 0 if scoring_fields.nil?

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
      group_by { |row| row[0] }. # Group by position
      transform_values { |rows| rows.map { |r| { field_name: r[1], value: r[2] } } }
  end

  # *_to_date_range intentionally exclude today, so that we can cache the values
  # and add today to them.
  def week_to_date_range
    Time.current.beginning_of_week..1.day.ago.end_of_day
  end

  def month_to_date_range
    Time.current.beginning_of_month..1.day.ago.end_of_day
  end

  def season_to_date_range
    @pool.start_end_range.begin.beginning_of_day..1.day.ago.end_of_day
  end
end
