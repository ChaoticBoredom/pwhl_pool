class LeaguePlayersController < ApplicationController
  def show
    @player = League::Player.find(params[:id])
    @pool = Pool.find(params[:pool_id])

    setup_services
    records = fetch_records

    @stats = @stat_service.raw_player_summary(@player, records)
    @scores = @scoring_service.raw_player_summary(@player, records)

    build_player_context

    render :show
  end

  def team_player
    @team_player = Pool::TeamPlayer.find(params[:id])
    @player = @team_player.league_player
    @pool = @team_player.pool

    setup_services
    records = fetch_records

    @stats = @stat_service.player_summary(@team_player, records)
    @scores = @scoring_service.player_summary(@team_player, records)

    build_player_context

    render :show
  end

  private

  def fetch_records
    PlayerRecordQuery.new(
      player_ids: [@player.id],
      season_id: @pool.season_id
    ).records
  end

  def setup_services
    @config = @pool.league.stat_config
    @stat_service = PlayerStatService.new(@config::STATS)
    @scoring_service = PlayerScoringService.new(@pool.scoring)
    @calculator = ScoringCalculator.new(@pool.scoring)
  end

  def build_player_context
    @expanded_scores = @stats.transform_values do |windowed_summary|
      windowed_summary.transform_values do |window|
        scored = @calculator.calculate_by_field(window.map { |k, v| { k => v } }, @player.roster_type)
        @config::STATS[@player.roster_type].each_with_object({}) do |field, h|
          h[field] = scored.fetch(field.to_s, scored.fetch(field, 0.0))
        end
      end
    end
  end
end
