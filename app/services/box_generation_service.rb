class BoxGenerationService
  class BoxGenerationError < StandardError; end
  def initialize(pool, config = BoxGeneration::Config.new, season_id: nil)
    @pool = pool
    @config = config
    @season_id = season_id || pool.display_season_id
    @position_groups = pool.league.stat_config::POSITION_GROUPS
  end

  def call
    players = fetch_players
    scores = score_players(players)
    sorted = sort_and_group(scores)
    box_players = generate_boxes(sorted)
    validate_no_duplicates!(box_players)
    box_players
  end

  private

  def fetch_players
    scope = League::Player.where(league_id: @pool.league_id)
    scope = scope.where(current_team: League::Team.where(short_code: @config.teams)) if @config.teams
    scope = scope.where.not(id: @config.excluded_player_ids) if @config.excluded_player_ids
    scope
  end

  def score_players(players)
    records = PlayerRecordQuery.new(players: players, season_id: @season_id).records
    calculator = ScoringCalculator.new(@pool.scoring)

    players.each_with_object({}) do |player, r_hash|
      player_records = records[player.id] || []
      r_hash[player.id] = calculator.calculate(player_records, player.roster_type)
    end
  end

  def sort_and_group(scores)
    player_lookup = League::Player.
      where(id: scores.keys).
      index_by(&:id)

    details = scores.each_with_object({}) do |(id, score), r_hash|
      player = player_lookup[id]
      r_hash[id] = {
        id: id,
        name: player.name,
        position: normalized_position(player.position),
        team_id: player.current_team_id,
        current_team_short_code: player.current_team_short_code,
        rookie: player.rookie?,
        score: score,
      }
    end

    details.
      values.
      group_by { |d| d[:team_id] }.
      transform_values do |team_players|
        groups = team_players.
          sort_by { |d| -d[:score] }.
          group_by { |d| [d[:position], d[:rookie]] }

        # Precompute nil-rookie variants so candidates_for is a plain lookup
        groups.keys.map(&:first).uniq.each do |position|
          groups[[position, nil]] = (
            groups[[position, false]].to_a +
            groups[[position, true]].to_a
          ).sort_by { |d| -d[:score] }
        end

        groups
      end
  end

  def generate_boxes(sorted)
    @config.boxes.each_with_object({}) do |box_def, result|
      players = players_for_box(sorted, box_def)
      result[box_def.name] = players.compact.map do |p|
        {
          id: p[:id],
          name: p[:name],
          score: p[:score],
          team_id: p[:team_id],
          current_team_short_code: p[:current_team_short_code],
        }
      end
    end
  end

  def players_for_box(sorted, box_def)
    if @config.per_team?
      sorted.flat_map do |_, team_groups|
        candidates_for(team_groups, box_def)[box_def.rank_range]
      end
    else
      sorted.flat_map { |_, team_groups| candidates_for(team_groups, box_def) }.
        sort_by { |p| -p[:score] }.
        then { |c| c[box_def.rank_range] }
    end
  end

  def candidates_for(team_groups, box_def)
    team_groups[[box_def.position, box_def.rookie]].to_a
  end

  def normalized_position(position)
    @position_groups.find { |_, v| v.include?(position) }&.first || position
  end

  def validate_no_duplicates!(box_players)
    all_ids = box_players.values.flat_map { |v| v.map { |p| p[:id] } }
    duplicates = all_ids.select { |id| all_ids.count(id) > 1 }.uniq

    if duplicates.any?
      duplicate_names = League::Player.where(id: duplicates).pluck(:name)
      raise BoxGenerationError, "Players appear in multiple boxes: #{duplicate_names.join(', ')}"
    end
  end
end
