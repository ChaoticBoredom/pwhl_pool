RSpec.shared_examples "PlayerPositionTypes" do
  it {
    should define_enum_for(:position_type).with_values(
      wildcard: 0,
      ir: 1,
      forward: 10,
      defense: 20,
      goalie: 30,
    ).with_prefix(:position).validating
  }
end
