class PoolScoringController < ApplicationController
  before_action :set_pool

  def index
    @stat_config = @pool.league.stat_config
    scorings_by_field = @pool.
      scoring.
      to_h { |scoring| [[scoring.roster_type, scoring.field_name], scoring] }

    @scorings_by_roster_type = @stat_config::SCOREABLE_STATS.to_h do |roster, fields|
      [
        roster,
        fields.filter_map do |field|
          scoring = scorings_by_field[[roster.to_s, field.to_s]]
          next if scoring.nil? && scorings_by_field.any?

          value = scoring&.value || @stat_config::DEFAULT_SCORING.dig(roster, field.to_sym) || 0.0
          { id: scoring&.id, field_name: field.to_s, roster_type: roster.to_s, value: value }
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
