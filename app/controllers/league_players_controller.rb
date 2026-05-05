class LeaguePlayersController < ApplicationController
  def team_player
    @team_player = Pool::TeamPlayer.find(params[:id])
    @player = @team_player.league_player
    @pool = @team_player.pool

    @stat_service = PlayerStatService.new(@pool)
    @scoring_service = PlayerScoringService.new(@pool.scoring, @pool)

    @stats = @stat_service.player_summary(@team_player)
    @scores = @scoring_service.player_summary(@team_player)
    @expanded_scores = @scoring_service.calculate_scores_across_hash(@stats, @player.position)

    render :show
  end
end
