module DateFiltering
  extend ActiveSupport::Concern

  private

  def calculate_aggregate(records, position)
    raise NotImplementedError, "#{self.class.name} must implement #calculate_aggregate"
  end

  def default_return
    raise NotImplementedError, "#{self.class.name} must implement #default_return"
  end

  def score_window(records, position, window, clip_range: nil)
    effective_range = clip_range ? intersect_ranges(window, clip_range) : window
    return default_return unless effective_range

    calculate_aggregate(records_in_range(records, effective_range), position)
  end

  def records_in_range(records, range)
    records.select { |r| range.cover?(r.league_game.start_time) }
  end

  def intersect_ranges(a, b)
    start = [a.begin, b.begin].compact.max
    stop = [a.end, b.end].compact.min
    start <= stop ? start..stop : nil
  end

  def build_windowed_summary(records, position, clip_range: nil)
    today = score_window(records, position, Time.current.all_day, clip_range:)
    yesterday = score_window(records, position, 1.day.ago.all_day, clip_range:)
    week_to_date = score_window(records, position, week_to_date_range, clip_range:)
    month_to_date = score_window(records, position, month_to_date_range, clip_range:)
    season_to_date = score_window(records, position, season_to_date_range, clip_range:)

    {
      today: today,
      yesterday: yesterday,
      week_to_date: yield(week_to_date, today),
      month_to_date: yield(month_to_date, today),
      season_to_date: yield(season_to_date, today),
    }
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
    ..1.day.ago.end_of_day
  end
end
