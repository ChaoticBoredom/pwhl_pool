class PlayerRecordQuery
  def initialize(players, season_id:)
    @season_id = season_id
    @player_ids = extract_player_ids(players)
  end

  def records
    ids = historical_ids + today_ids
    materialize(ids).group_by(&:league_player_id)
  end

  private

  def historical_ids
    Rails.cache.fetch(cache_key) do
      fetch_ids_for_range(..1.day.ago.end_of_day)
    end
  end

  def today_ids
    fetch_ids_for_range(Time.current.all_day)
  end

  def fetch_ids_for_range(range)
    stat_classes.flat_map do |klass|
      klass.
        joins(:league_game).
        where(league_player_id: @player_ids).
        where(league_games: { season_id: @season_id, start_time: range }).
        pluck(:id)
    end
  end

  def materialize(ids)
    return [] if ids.empty?

    stat_classes.flat_map do |klass|
      klass.includes(:league_game).where(id: ids)
    end.to_a
  end

  def cache_key
    ["player_records", @season_id, Date.current.to_s, Digest::SHA1.hexdigest(@player_ids.sort.join)]
  end

  def extract_player_ids(players)
    return [] if players.empty?

    case players.first
    when Pool::TeamPlayer then players.map(&:league_player_id).uniq
    when League::Player then players.map(&:id)
    else
      raise ArgumentError, "Unsupported player type: #{players.first.class}"
    end
  end

  def stat_classes
    [Pwhl::SkaterStat, Pwhl::GoalieStat]
  end
end
