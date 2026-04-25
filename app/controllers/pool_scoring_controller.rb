class PoolScoringController < ApplicationController
  def index
    scorings = Pool.includes(:scoring).find(params[:pool_id]).scoring

    @skater_scorings = scorings.skater
    @goalie_scorings = scorings.goalie

    render :index
  end
end
