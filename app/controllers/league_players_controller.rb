class LeaguePlayersController < ApplicationController
  def team_player
    @team_player = Pool::TeamPlayer.find(params[:id])
    @player = @team_player.league_player
    @pool = @team_player.pool

    records = PlayerRecordQuery.new([@team_player], season_id: @pool.season_id).records

    @stat_service = PlayerStatService.new
    @scoring_service = PlayerScoringService.new(@pool.scoring)
    @calculator = ScoringCalculator.new(@pool.scoring)

    @stats = @stat_service.player_summary(@team_player, records)
    @scores = @scoring_service.player_summary(@team_player, records)

    @expanded_scores = @stats.transform_values do |windowed_summary|
      windowed_summary.transform_values { |window| @calculator.calculate([window], @player.position) }
    end

    render :show
  end
end
