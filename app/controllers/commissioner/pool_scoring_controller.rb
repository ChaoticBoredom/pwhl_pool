class Commissioner::PoolScoringController < Commissioner::BaseController
  def update
    Pool::Scoring.transaction do
      @pool.scoring.destroy_all
      scoring_params.each do |entry|
        next if entry[:value].to_f.zero?
        next unless valid_scoreable?(entry[:roster_type], entry[:field_name])

        @pool.scoring.create!(
          field_name: entry[:field_name],
          roster_type: entry[:roster_type],
          value: entry[:value].to_f,
        )
      end
    end

    head :no_content
  rescue ActiveRecord::RecordInvalid => e
    render json: { errors: e.message }, status: :unprocessable_content
  end

  private

  def scoring_params
    params.permit(scoring: [:field_name, :roster_type, :value])[:scoring] || []
  end

  def valid_scoreable?(roster_type, field_name)
    stat_config = @pool.league.stat_config
    stat_config::SCOREABLE_STATS[roster_type.to_sym]&.map(&:to_s)&.include?(field_name.to_s)
  end

  def pool_includes
    [:scoring, :league]
  end
end
