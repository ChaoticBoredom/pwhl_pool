module PlayerScoring
  extend ActiveSupport::Concern

  def score_for_today(pool = pool_to_use)
    score_for_date(DateTime.current, pool)
  end

  def score_for_yesterday(pool = pool_to_use)
    cached_score("yesterday", pool) do
      score_for_date(DateTime.yesterday, pool)
    end
  end

  # The following 'to_date' methods do not include today so they can be cached with today's scoring added
  def score_for_week_to_date(pool = pool_to_use)
    cached_score("week_to_date", pool) do
      score_for_date_range(DateTime.current.beginning_of_week..DateTime.yesterday.end_of_day, pool)
    end
  end

  def score_for_month_to_date(pool = pool_to_use)
    cached_score("month_to_date", pool) do
      score_for_date_range(DateTime.current.beginning_of_month..DateTime.yesterday.end_of_day, pool)
    end
  end

  def score_for_season_to_date(pool = pool_to_use)
    cached_score("season_to_date", pool) do
      start = pool.start_end_range.begin
      score_for_date_range(start..DateTime.yesterday.end_of_day, pool)
    end
  end

  def cached_score(suffix, pool = pool_to_use, &block)
    Rails.cache.fetch("scores/#{scoring_cache_key(pool)}/#{suffix}", expires_at: Time.current.tomorrow.beginning_of_day, &block)
  end

  def score_for_date(date, pool = pool_to_use)
    target_date = date.to_date

    stat = if records.loaded?
      records.to_a.detect { |r| r.league_game.start_time.to_date == target_date }
    else
      records.for_date(target_date)
    end

    calculate_aggregate(stat, pool)
  end

  def score_for_date_range(date_range, pool = pool_to_use)
    return 0 if pool.nil?

    if records.loaded?
      stats = records.to_a.select { |r| date_range.cover?(r.start_time.to_date) }
      calculate_aggregate(stats, pool)
    else
      calculate_aggregate(records.
        for_season(pool.season_id).
        for_date_range(date_range), pool)
    end
  end

  def score_for_season(pool = pool_to_use)
    score_for_date_range(pool.start_end_range)
  end

  def scores(pool = pool_to_use)
    to_date_scores = {
      season_to_date: score_for_season_to_date(pool),
      month_to_date: score_for_month_to_date(pool),
      week_to_date: score_for_week_to_date(pool),
    }

    todays_score = score_for_date(DateTime.current, pool)
    to_date_scores.
      transform_values { |v| v + todays_score }.
      merge({
        yesterday: score_for_yesterday(pool),
        today: todays_score,
      })
  end

  def pool_to_use
    nil
  end

  def scoring_cache_key(pool = pool_to_use)
    player_part = (respond_to?(:league_player) ? league_player : self).cache_key_with_version

    "scores/#{player_part}/pool-#{pool.id}"
  end

  private

  def calculate_aggregate(scope, pool)
    return 0 if scope.blank?
    return 0 if pool.nil?

    scorings = get_scoring_fields(pool)
    fields = scorings.pluck(:field_name)

    raw_data = if scope.respond_to?(:pluck)
      scope.pluck(*fields)
    else
      [fields.map { |f| scope[f] }]
    end

    scorings.sum do |s|
      index = fields.index(s[:field_name])
      raw_data.sum { |row| parse_field(row.is_a?(Array) ? row[index] : row) } * s[:value]
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

  def get_scoring_fields(pool)
    Rails.cache.fetch("scores/#{pool.cache_key_with_version}/#{position}", expires_in: 1.month) do
      scorings = pool.scoring.where(position: position).pluck(:field_name, :value)
      scorings.map! { |s| [:field_name, :value].zip(s).to_h }
    end
  end
end
