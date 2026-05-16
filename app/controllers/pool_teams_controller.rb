class PoolTeamsController < ApplicationController
  def show
    id = params[:id]
    @pool_team = Pool::Team.
      includes(:owner, pool: :league, pool_team_players: [:pool_box, { league_player: :current_team }]).
      find(id)
    @pool = @pool_team.pool
    records = PlayerRecordQuery.new(players: @pool_team.pool_team_players, season_id: @pool.season_id).records
    @scoring_service = PlayerScoringService.new(@pool.scoring)
    @current_team = @pool_team.pool_team_players.select(&:current?)
    @previous_team = @pool_team.pool_team_players.reject(&:current?)

    @player_summaries = @scoring_service.player_summaries(@pool_team.pool_team_players, records)
    @total_score = @scoring_service.team_scores([@pool_team], records)[@pool_team.id]
    @player_games = UpcomingGamesService.new.player_schedule(@current_team)

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

  def update
    @pool_team = Pool::Team.find(params[:id])
    return head :forbidden unless current_user == @pool_team.owner

    if @pool_team.update(team_name_params)
      render json: { message: "Team Name updated!" }
    else
      render json: { errors: @pool_team.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update_roster
    @pool_team = Pool::Team.find(params[:id])
    return head :forbidden unless current_user == @pool_team.owner

    @pool = @pool_team.pool
    unless @pool.trading_blocked?
      render json: { error: "Trades are currently locked for this pool", reason: "trades_closed" }, status: :forbidden
      return
    end

    box_by_player_id = @pool.pool_boxes.each_with_object({}) do |pb, hash|
      pb.league_player_ids.each { |pid| hash[pid] = pb }
    end

    original_team = @pool_team.current_team.pluck(:league_player_id)
    new_team = params[:new_player_ids]

    dropping = original_team - new_team
    @pool_team.current_team.where(league_player_id: dropping).update(dropped_at: Time.current)

    adding = new_team - original_team
    adding.each do |pid|
      @pool_team.pool_team_players.create(
        league_player_id: pid,
        added_at: Time.current,
        pool_box: box_by_player_id[pid]
      )
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

  def team_name_params
    params.require(:pool_team).permit(:team_name)
  end
end
