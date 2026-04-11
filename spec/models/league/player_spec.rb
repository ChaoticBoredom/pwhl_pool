require "rails_helper"

RSpec.describe League::Player, type: :model do
  it_behaves_like "PlayerPositions"

  it { should validate_presence_of(:name) }
  it { should validate_presence_of(:type) }
  it { should validate_presence_of(:api_id) }

  it { should belong_to(:league) }
  it { should belong_to(:current_team) }

  context "when type is unset" do
    context "when league is 'PWHL'" do
      let(:league) { create(:league, :pwhl) }

      [
        { position: "skater", result: "Pwhl::Skater" },
        { position: "goalie", result: "Pwhl::Goalie" },
      ].each do |h|
        it "should set type to #{h[:result]} when position is #{h[:position]}" do
          current_team = create(:league_team, league: league)
          player = League::Player.create(
            name: "Jane Doe",
            api_id: "api_key",
            current_team: current_team,
            league: league,
            position: h[:position],
          )
          expect(player.type).to eq(h[:result])
        end
      end
    end
  end
end
