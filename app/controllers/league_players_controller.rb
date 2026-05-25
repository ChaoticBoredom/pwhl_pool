class LeaguePlayersController < ApplicationController
  def team_player
    @team_player = Pool::TeamPlayer.find(params[:id])
    @player = @team_player.league_player
    @pool = @team_player.pool

    records = PlayerRecordQuery.new(player_ids: [@team_player.league_player_id], season_id: @pool.season_id).records

    @stat_service = PlayerStatService.new
    @scoring_service = PlayerScoringService.new(@pool.scoring)
    @calculator = ScoringCalculator.new(@pool.scoring)

    @stats = @stat_service.player_summary(@team_player, records)
    @scores = @scoring_service.player_summary(@team_player, records)

    @expanded_scores = @stats.transform_values do |windowed_summary|
      windowed_summary.transform_values do |window|
        @calculator.calculate_by_field(window.map { |k, v| { k => v } }, @player.roster_type)
      end
    end

    render :show
  end
end
1
