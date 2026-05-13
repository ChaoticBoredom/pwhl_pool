class PlayerRecordQuery
  def initialize(players, season_id:)
    @season_id = season_id
    @player_ids = case players
    when Array then players
    else extract_player_ids(players)
    end
  end

  def records
    (historical_records + today_records).group_by(&:league_player_id)
  end

  private

  def historical_records
    @player_ids.flat_map do |player_id|
      Rails.cache.fetch(player_cache_key(player_id)) do
        fetch_records_for_range(..1.day.ago.end_of_day, player_ids: player_id).map do |r|
          r.attributes.merge("_class" => r.class.name)
        end
      end.map do |attrs|
        attrs["_class"].constantize.instantiate(attrs.except("_class"))
      end
    end
  end

  def today_records
    fetch_records_for_range(Time.current.all_day)
  end

  def stat_scope(klass, range, player_ids: @player_ids)
    klass
      .joins(:league_game)
      .where(league_player_id: player_ids)
      .where(league_games: { season_id: @season_id, start_time: range })
  end

  def fetch_records_for_range(range, player_ids: @player_ids)
    stat_classes.flat_map do |klass|
      stat_scope(klass, range, player_ids: player_ids).includes(:league_game)
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
