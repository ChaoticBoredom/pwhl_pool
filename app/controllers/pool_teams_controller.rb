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
      associations: { records: :league_game },
    ).call

    ActiveRecord::Associations::Preloader.new(
      records: skaters,
      associations: { records: :league_game },
    ).call

    render :show
  end

  def update_roster
    @pool_team = Pool::Team.find(params[:id])
    @pool = @pool_team.pool

    original_team = @pool_team.current_team.pluck(:league_player_id)
    new_team = params[:new_player_ids]

    dropping = original_team - new_team
    @pool_team.current_team.where(league_player_id: dropping).update(dropped_at: Time.current)

    adding = new_team - original_team
    (new_team - original_team).each do |pid|
      @pool_team.pool_team_players.create(league_player_id: pid, added_at: Time.current)
    end

    dropped_names = League::Player.where(id: dropping).pluck(:name)
    added_names = League::Player.where(id: adding).pluck(:name)

    render json: {
      message: "Roster updated!",
      added_players: added_names,
      dropped_players: dropped_names,
    }
  end
end
