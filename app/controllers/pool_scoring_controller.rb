class PoolScoringController < ApplicationController
  before_action :set_pool

  def index
    @stat_config = @pool.league.stat_config
    scorings_by_field = @pool.
      scoring.
      to_h { |scoring| [[scoring.roster_type, scoring.field_name], scoring.value] }

    @scorings_by_roster_type = @stat_config::SCOREABLE_STATS.to_h do |roster, fields|
      [
        roster,
        fields.map do |field|
          scoring = scorings_by_field[[roster.to_s, field.to_s]]
          { field_name: field.to_s, value: scoring }
        end,
      ]
    end

    render :index
  end

  private

  def set_pool
    @pool = Pool.includes(:scoring, :league).find(params[:pool_id])
  end
end
