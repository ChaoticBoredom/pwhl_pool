class Reports::ScoreSummaryService
  def initialize(pool, range, breakdowns:, period: nil)
    @pool = pool
    @range = range
    @breakdowns = Array(breakdowns)
    @period = period
    @calculator = ScoringCalculator.new(pool.scoring)

    @teams_by_id = League::Team.short_codes_by_league(@pool.league_id)
  end

  def call
    all_team_players = @pool.pool_teams.flat_map(&:pool_team_players)
    all_player_ids = all_team_players.map(&:league_player_id).uniq

    records = PlayerRecordQuery.new(
      player_ids: all_player_ids,
      season_id: @pool.season_id
    ).records

    filtered_records = filter_by_range(records)
    buckets = generate_buckets

    @pool.pool_teams.includes(pool_team_players: [:league_player, :pool_box]).map do |pool_team|
      team_players = pool_team.pool_team_players
      build_team_report(pool_team, team_players, filtered_records, buckets)
    end
  end

  private

  def filter_by_range(records)
    records.transform_values do |player_records|
      player_records.
        select { |r| @range.cover?(r.start_time) }.
        sort_by(&:start_time)
    end
  end

  def generate_buckets
    return [[@range.first, @range.last]] if @period.nil?

    step = case @period
    when "day" then 1.day
    when "week" then 1.week
    when "month" then 1.month
    end

    buckets = []
    current = case @period
    when "week" then @range.first.beginning_of_week
    when "month" then @range.first.beginning_of_month
    else @range.first
    end

    while current < @range.last
      bucket_end = [current + step - 1.second, @range.last].min
      buckets << [current, bucket_end]
      current += step
    end
    buckets
  end

  def clip_to_active_range_and_bucket(player_records, team_player, bucket_from, bucket_to)
    effective_from = [team_player.added_at, bucket_from].max
    effective_to = [team_player.dropped_at, bucket_to].compact.min

    return [] if effective_from > effective_to

    player_records.select do |r|
      r.start_time >= effective_from && r.start_time <= effective_to
    end
  end

  def build_team_report(pool_team, team_players, records, buckets)
    player_data = team_players.map do |tp|
      player_records = records[tp.league_player_id] || []
      build_player_data(tp, player_records, buckets)
    end

    report = {
      id: pool_team.id,
      team_name: pool_team.team_name,
      total_score: player_data.sum { |p| p[:total_score] },
    }

    if include_breakdown?("by_category")
      report[:by_category] = sum_by_category(player_data.map { |p| p[:by_category] })
    end

    if include_breakdown?("by_player")
      report[:by_player] = player_data.map do |p|
        player = p.except(:bucket_scores)
        full_breakdown? ? player : player.except(:by_category)
      end
    end

    if @period
      report[:periods] = build_period_report(buckets, player_data)
    end

    report
  end

  def build_player_data(team_player, player_records, buckets)
    player = team_player.league_player

    bucket_scores = buckets.map do |bucket_from, bucket_to|
      clipped = clip_to_active_range_and_bucket(player_records, team_player, bucket_from, bucket_to)
      by_field = normalize_by_category(@calculator.calculate_by_field(clipped, player.roster_type), player.roster_type)
      {
        from: bucket_from,
        to: bucket_to,
        by_field: by_field,
        total: by_field.values.sum,
      }
    end

    total_by_field = bucket_scores.each_with_object(Hash.new(0.0)) do |b, r_hash|
      b[:by_field].each { |field, score| r_hash[field] += score }
    end

    team_short_codes = player_records.
      map(&:league_team_id).
      uniq.
      filter_map { |id| @teams_by_id[id] }
    {
      league_player_id: team_player.league_player_id,
      name: player.name,
      added_at: team_player.added_at,
      dropped_at: team_player.dropped_at,
      total_score: total_by_field.values.sum,
      by_category: total_by_field,
      bucket_scores: bucket_scores,
      position: player.position,
      team_short_codes: team_short_codes,
      pool_box: {
        id: team_player.pool_box.id,
        name: team_player.pool_box.name,
        position: team_player.pool_box.position,
      },
    }
  end

  def normalize_by_category(by_field, roster_type)
    PlayerStatService::STATS[roster_type].each_with_object({}) do |field, h|
      h[field.to_s] = by_field.fetch(field.to_s, by_field.fetch(field, 0.0))
    end
  end

  def build_period_report(buckets, player_data)
    buckets.map.with_index do |(bucket_from, bucket_to), i|
      period = {
        from: bucket_from,
        to: bucket_to,
        total_score: player_data.sum { |p| p[:bucket_scores][i][:total] },
      }

      if include_breakdown?("by_category")
        period[:by_category] = sum_by_category(player_data.map { |p| p[:bucket_scores][i][:by_field] })
      end

      if include_breakdown?("by_player")
        period[:by_player] = player_data.map do |p|
          bucket = p[:bucket_scores][i]
          result = {
            league_player_id: p[:league_player_id],
            name: p[:name],
            total_score: bucket[:total],
          }
          result[:by_category] = bucket[:by_field] if full_breakdown?
          result
        end
      end

      period
    end
  end

  def sum_by_category(by_field_array)
    by_field_array.each_with_object(Hash.new(0.0)) do |by_field, totals|
      next unless by_field
      by_field.each { |field, score| totals[field] += score }
    end
  end

  def include_breakdown?(breakdown)
    full_breakdown? || @breakdowns.include?(breakdown)
  end

  def full_breakdown?
    @full_breakdown ||= @breakdowns.include?("full_breakdown")
  end
end
