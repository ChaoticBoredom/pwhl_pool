class PlayerRecordQuery
  def initialize(season_id:, player_ids: nil, players: nil)
    @season_id = season_id
    @player_ids = if player_ids
      player_ids.uniq
    elsif players
      extract_player_ids(players)
    else
      raise ArgumentError, "Must provide either player_ids: or players:"
    end
  end

  def records
    (historical_records + today_records).group_by(&:league_player_id)
  end

  private

  def historical_records
    cached = {}
    uncached_ids = []

    @player_ids.each do |player_id|
      value = Rails.cache.read(player_cache_key(player_id))
      if value
        cached[player_id] = value
      else
        uncached_ids << player_id
      end
    end

    if uncached_ids.any?
      fetched = fetch_records_for_range(..1.day.ago.end_of_day, player_ids: uncached_ids).
        group_by(&:league_player_id)

      uncached_ids.each do |player_id|
        records = (fetched[player_id] || []).map do |r|
          r.attributes.merge("_class" => r.class.name)
        end
        Rails.cache.write(player_cache_key(player_id), records)
        cached[player_id] = records
      end
    end

    cached.values.flatten.map do |record|
      record["_class"].constantize.instantiate(record.except("_class"))
    end
  end

  def today_records
    fetch_records_for_range(Time.current.all_day)
  end

  def stat_scope(klass, range, player_ids: @player_ids)
    klass.
      where(league_player_id: player_ids).
      where(season_id: @season_id).
      where(start_time: range)
  end

  def fetch_records_for_range(range, player_ids: @player_ids)
    stat_classes.flat_map do |klass|
      stat_scope(klass, range, player_ids: player_ids)
    end
  end

  def player_cache_key(player_id)
    ["player_records", @season_id, Time.zone.today.to_s, player_id]
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
