class PoolBoxesController < ApplicationController
  def index
    @pool = Pool.includes(:scoring).find(params[:pool_id])
    @boxes = Pool::Box.where(pool_id: @pool.id)

    current_pool_team = current_user&.pool_teams&.find_by(pool_id: @pool.id)
    @selected_ids = []
    if current_pool_team
      @selected_ids = current_pool_team.current_team.pluck(:league_player_id)
    end

    all_players = @boxes.flat_map(&:players).uniq(&:id)

    pss = PlayerScoringService.new(@pool.scoring, @pool)

    @player_summaries = pss.raw_player_summaries(all_players)

    render :index
  end
end
