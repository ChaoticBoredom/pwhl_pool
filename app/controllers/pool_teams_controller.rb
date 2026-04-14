class PoolTeamsController < ApplicationController
  def show
    id = params[:id]
    @pool_team = Pool::Team.includes(pool_team_players: :league_player).find(id)
    render json: @pool_team,
      only: [:id, :team_name, :total_score],
      include: {
        owner: { only: [:id, :name] },
        current_team: {
          only: [:id, :league_player_id],
          methods: [:name, :current_team_id, :scores],
        },
        previous_team: {
          only: [:id, :league_player_id, :dropped_at],
          methods: [:name, :current_team_id, :scores],
        },
      }
  end
end
