class ScoringCalculator
  def initialize(scorings)
    @scorings = format_scorings(scorings).with_indifferent_access
  end

  def calculate(inputs, roster_type)
    calculate_by_field(inputs, roster_type).values.sum
  end

  def calculate_by_field(inputs, roster_type)
    return {} if inputs.empty?

    scoring_fields = @scorings[roster_type]
    return {} if scoring_fields.nil?

    normalized = normalize_inputs(inputs)

    all_fields(normalized, scoring_fields).each_with_object({}) do |field, r_hash|
      scoring = scoring_fields.find { |s| s.key(field) }
      value = scoring ? inputs.sum { |input| parse_field(input[field] || input[field.to_sym]) } * scoring[:value] : 0.0
      r_hash[field] = value
    end
  end

  private

  def all_fields(inputs, scoring_fields)
    (input_field_names(inputs) + scoring_fields.map { |s| s[:field_name] }).uniq
  end

  def input_field_names(inputs)
    inputs.flat_map { |input| input.keys.map(&:to_s) }.uniq
  end

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
