class ScoringCalculator
  def initialize(scorings)
    @scorings = format_scorings(scorings).with_indifferent_access
  end

  def calculate(inputs, position)
    return 0 if inputs.empty?

    scoring_fields = @scorings[position]
    return 0 if scoring_fields.nil?

    scoring_fields.sum do |s|
      (inputs.sum { |input| parse_field(input[s[:field_name]] || parse_field(input[s[:field_name].to_sym])) }) * s[:value]
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
    scorings.pluck(:position, :field_name, :value).
      group_by { |row| row[0] }.
      transform_values { |rows| rows.map { |r| { field_name: r[1], value: r[2] } } }
  end
end
