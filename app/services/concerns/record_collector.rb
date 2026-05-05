module RecordCollector
  extend ActiveSupport::Concern

  included do
    attr_reader :pool
  end

  private

  def stat_classes
    raise NotImplementedError, "#{self.class.name} must implement #stat_classes"
  end

  def calculate_aggregate(records, position)
    raise NotImplementedError, "#{self.class.name} must implement #stat_classes"
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
    records = stat_classes.flat_map do |klass|
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
end
