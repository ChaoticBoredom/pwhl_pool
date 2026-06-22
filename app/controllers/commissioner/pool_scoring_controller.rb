class Commissioner::PoolScoringController < Commissioner::BaseController
  class BaseScoringError < StandardError
    attr_reader :fields

    def initialize(fields)
      @fields = fields
      super("#{label}: #{fields.inspect}")
    end

    def label
      raise NotImplementedError
    end
  end

  class IncompleteScoringError < BaseScoringError
    def label
      "Missing scoreable fields"
    end
  end

  class UnexpectedScoringError < BaseScoringError
    def label
      "Unexpected scoring fields"
    end
  end

  def create
    @stat_config = @pool.league.stat_config
    ensure_scoreable_fields_match!

    Pool::Scoring.transaction do
      scoring_params.each { |entry| @pool.scoring.create!(entry.except(:id)) }
    end

    @scorings_by_roster_type = @pool.scoring.reload.group_by(&:roster_type).transform_values do |scorings|
      scorings.map { |s| { id: s.id, field_name: s.field_name, value: s.value } }
    end

    render template: "pool_scoring/index", status: :created
  rescue BaseScoringError => e
    render json: { error: e.label, fields: e.fields }, status: :unprocessable_content
  end

  def update
    Pool::Scoring.transaction do
      scoring_params.each do |entry|
        @pool.scoring.find(entry[:id]).update!(value: entry[:value])
      end
    end

    head :ok
  end

  private

  def ensure_scoreable_fields_match!
    submitted = scoring_params.map { |entry| [entry[:roster_type].to_s, entry[:field_name].to_s] }
    expected = @stat_config::SCOREABLE_STATS.flat_map do |roster, fields|
      fields.map { |field| [roster.to_s, field.to_s] }
    end

    missing = expected - submitted
    raise IncompleteScoringError, missing if missing.any?

    unexpected = submitted - expected
    raise UnexpectedScoringError, unexpected if unexpected.any?
  end

  def scoring_params
    params.permit(scoring: [:id, :field_name, :roster_type, :value])[:scoring] || []
  end

  def pool_includes
    [:scoring, :league]
  end
end
