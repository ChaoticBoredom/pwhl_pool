class PoolTeamsController < ApplicationController
  def show
    id = params[:id]
    @pool_team = Pool::Team.includes(pool_team_players: :league_player).find(id)
    @pool = @pool_team.pool

    # Preload data to speedify things
    all_players = @pool_team.league_players.to_a
    goalies = all_players.select(&:goalie?)
    skaters = all_players.select(&:skater?)

    today_range = Date.current.all_day

    ActiveRecord::Associations::Preloader.new(
      records: goalies,
      associations: { records: :league_game},
    ).call

    ActiveRecord::Associations::Preloader.new(
      records: skaters,
      associations: { records: :league_game},
    ).call

    render :show
  end
end
