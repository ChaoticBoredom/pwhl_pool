class PoolBoxesController < ApplicationController
  def index
    @boxes = Pool::Box.includes(pool: :scoring).where(pool_id: params[:pool_id])
    @pool = Pool.find(params[:pool_id])

    current_pool_team = current_user&.pool_teams&.find_by(pool_id: params[:pool_id])
    if current_pool_team
      @selected_ids = current_pool_team.current_team.pluck(:league_player_id)
    end

    all_players = @boxes.flat_map(&:players).uniq
    ActiveRecord::Associations::Preloader.new(
      records: all_players,
      associations: [{ records: :league_game }, :current_team]
    ).call

    @pss = PlayerScoringService.new(@pool.scoring, @pool)

    render :index
  end
end
