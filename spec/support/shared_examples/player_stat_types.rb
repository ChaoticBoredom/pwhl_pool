RSpec.shared_examples "PlayerStatTypes" do
  it {
    should define_enum_for(:stat_type).with_values(
      skater: 100,
      goalie: 200,
    ).validating
  }
end
