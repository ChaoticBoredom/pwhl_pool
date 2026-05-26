class ScoringCalculator
  def initialize(scorings)
    @scorings = format_scorings(scorings).with_indifferent_access
  end

  def calculate(inputs, roster_type)
    calculate_by_field(inputs, roster_type).values.sum
  end

  def calculate_by_field(inputs, roster_type)
    return Hash.new(0.0) if inputs.empty?

    scoring_fields = @scorings[roster_type]
    return Hash.new(0.0) if scoring_fields.nil?

    normalized = normalize_inputs(inputs)

    scoring_fields.each_with_object(Hash.new(0.0)) do |scoring, r_hash|
      field = scoring[:field_name]
      r_hash[field] = normalized.sum { |input| parse_field(input[field]) } * scoring[:value]
    end
  end

  private

  def parse_field(val)
    case val
    when true then 1
    when false then 0
    when ActiveSupport::Duration then val.in_minutes.to_i
    else val.to_i
    end
  end

  def format_scorings(scorings)
    scorings.pluck(:roster_type, :field_name, :value).
      group_by { |row| row[0] }.
      transform_values { |rows| rows.map { |r| { field_name: r[1], value: r[2] } } }
  end

  def normalize_inputs(inputs)
    inputs.map do |input|
      input.is_a?(Hash) ? input.with_indifferent_access : input.attributes.with_indifferent_access
    end
  end
end
