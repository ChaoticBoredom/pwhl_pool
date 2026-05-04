class LeaguePlayersController < ApplicationController
  def show
    @player = League::Player.includes(:current_team).find_by!(id: params[:id])

    render :show
  end
end
