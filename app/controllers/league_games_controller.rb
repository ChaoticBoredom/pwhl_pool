class LeagueGamesController < ApplicationController
  def show
    @game = League::Game.includes(:home_team, :away_team).find(params[:id])

    @home_team = @game.home_team
    @away_team = @game.away_team

    render :show
  end
end
