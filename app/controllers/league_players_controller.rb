class LeaguePlayersController < ApplicationController
  def show
    @player = League::Player.includes(:current_team).find(params[:id])
    @pool = Pool.find(params[:pool_id])

    render :show
  end

  def team_player
    @team_player = Pool::TeamPlayer.find(params[:id])
    @player = @team_player.league_player
    @pool = @team_player.pool

    @stat_service = PlayerStatService.new(@pool)
    @scoring_service = PlayerScoringService.new(@pool.scoring, @pool)

    @stats = @stat_service.player_summary(@team_player)
    @scores = @scoring_service.calculate_scores_across_hash(@stats, @player.position)

    render :show
  end
end
