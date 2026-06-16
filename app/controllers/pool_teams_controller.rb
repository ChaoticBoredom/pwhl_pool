class PoolTeamsController < ApplicationController
  def show
    id = params[:id]
    @pool_team = Pool::Team.
      includes(:owner, pool: :league, pool_team_players: [:pool_box, :league_player]).
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

  private

  def team_params
    params.require(:team).permit(:team_name, :pool_id)
  end

  def team_name_params
    params.require(:pool_team).permit(:team_name)
  end
end
