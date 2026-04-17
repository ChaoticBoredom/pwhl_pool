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
      associations: [ { records: :league_game}, :current_team ],
    ).call

    ActiveRecord::Associations::Preloader.new(
      records: skaters,
      associations: [ { records: :league_game}, :current_team ],
    ).call

    render :show
  end

  def create
    @team = Current.user.pool_teams.new(team_params)

    if @team.save
      render json: { data: @team }, status: :created
    else
      render json: { errors: @team.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update_roster
    @pool_team = Pool::Team.find(params[:id])
    return head :forbidden unless current_user == @pool_team.owner

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

  private

  def team_params
    params.require(:team).permit(:team_name, :pool_id)
  end
end
