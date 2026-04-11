require "rails_helper"

RSpec.describe League::Game, type: :model do
  it { should validate_presence_of(:api_id) }
  it { should validate_presence_of(:season_id) }
  it { should validate_presence_of(:type) }
  it { should validate_presence_of(:start_time) }
  it { should validate_presence_of(:home_team) }
  it { should validate_presence_of(:away_team) }

  it { should belong_to(:league) }
  it { should belong_to(:home_team) }
  it { should belong_to(:away_team) }

  it {
    should define_enum_for(:status).with_values(
      scheduled: 0,
      in_progress: 10,
      pending_final: 21,
      final: 20,
    ).validating
  }
end
