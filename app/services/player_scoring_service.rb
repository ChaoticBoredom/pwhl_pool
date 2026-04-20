class PlayerScoringService
  def initialize(scorings, pool)
    @scorings = format_scorings(scorings)
    @pool = pool
  end

  def score_for_today(player)
    score_for_date(Time.current, player)
  end

  def score_for_yesterday(player)
    with_cache("yesterday", player) do
      score_for_date(1.day.ago, player)
    end
  end

  def score_for_season(player)
    score_for_date_range(@pool.start_end_range, player)
  end

  # The following '_to_date' methods do not include todays scoring
  def score_for_week_to_date(player)
    with_cache("week_td", player) do
      score_for_date_range(Time.current.beginning_of_week..1.day.ago.end_of_day, player)
    end
  end

  def score_for_month_to_date(player)
    with_cache("month_td", player) do
      score_for_date_range(Time.current.beginning_of_month..1.day.ago.end_of_day, player)
    end
  end

  def score_for_season_to_date(player)
    with_cache("season_td", player) do
      start = @pool.start_end_range.begin
      score_for_date_range(start..1.day.ago.end_of_day, player)
    end
  end

  def score_for_date(date, player)
    target_date = date.to_date
    record = player.records.for_date(target_date)
    calculate_aggregate(record, player)
  end

  def score_for_date_range(date_range, player)
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

  private

  def with_cache(suffix, player, &block)
    key = [
      "player_scoring_service",
      player.cache_key_with_version,
      @pool.cache_key_with_version,
      Digest::MD5.hexdigest(@scorings.to_json),
      Time.current.to_date,
    ]

    Rails.cache.fetch(key, &block)
  end

  def calculate_aggregate(record, player)
    return 0 if record.nil?

    scoring_fields = @scorings[player.position]
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
