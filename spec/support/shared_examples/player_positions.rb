RSpec.shared_examples "PlayerPositions" do
  it {
    should define_enum_for(:position).with_values(
      skater: 100,
      goalie: 200,
    ).validating
  }
end
