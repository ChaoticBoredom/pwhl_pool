RSpec.shared_examples "PlayerStatTypes" do
  it {
    should define_enum_for(:roster_type).with_values(
      skater: 100,
      goalie: 200,
    ).validating
  }
end
