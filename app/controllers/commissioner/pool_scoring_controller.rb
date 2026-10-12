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

  before_action :require_stat_config
  rescue_from BaseScoringError, with: :render_scoring_error

  def create
    ensure_scoreable_fields_match!

    Pool::Scoring.transaction do
      scoring_params.each { |entry| @pool.scoring.create!(entry.except(:id)) }
    end

    @scorings_by_stat_type = @pool.scoring.reload.group_by(&:stat_type).transform_values do |scorings|
      scorings.map { |s| { id: s.id, field_name: s.field_name, value: s.value } }
    end

    render template: "pool_scoring/index", status: :created
  end

  def update
    ensure_scoreable_fields_match!

    Pool::Scoring.transaction do
      scoring_params.each do |entry|
        scoring = if entry[:id].present?
          @pool.scoring.find(entry[:id])
        else
          @pool.scoring.find_or_initialize_by(stat_type: entry[:stat_type], field_name: entry[:field_name])
        end

        scoring.update!(value: entry[:value])
      end
    end

    head :ok
  end

  private

  def require_stat_config
    @stat_config = @pool.league.stat_config
  end

  def ensure_scoreable_fields_match!
    submitted = scoring_params.map { |entry| [entry[:stat_type].to_s, entry[:field_name].to_s] }
    expected = @stat_config::SCOREABLE_STATS.flat_map do |roster, fields|
      fields.map { |field| [roster.to_s, field.to_s] }
    end

    missing = expected - submitted
    raise IncompleteScoringError, missing if missing.any?

    unexpected = submitted - expected
    raise UnexpectedScoringError, unexpected if unexpected.any?
  end

  def render_scoring_error(exception)
    render json: { error: exception.label, fields: exception.fields }, status: :unprocessable_content
  end

  def scoring_params
    @scoring_params ||= params.require(:scoring).map do |entry|
      entry.permit(:id, :field_name, :stat_type, :value)
    end
  end

  def pool_includes
    [:scoring, :league]
  end
end
