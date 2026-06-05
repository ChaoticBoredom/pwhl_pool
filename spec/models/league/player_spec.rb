require "rails_helper"

RSpec.describe League::Player, type: :model do
  it_behaves_like "PlayerRosterTypes"

  it { should validate_presence_of(:name) }
  it { should validate_presence_of(:type) }
  it { should validate_presence_of(:api_id) }

  it { should belong_to(:league) }
  it { should belong_to(:current_team).optional }

  context "when type is unset" do
    context "when league is 'PWHL'" do
      let(:league) { create(:league, :pwhl) }

      [
        { roster_type: "skater", result: "Pwhl::Skater" },
        { roster_type: "goalie", result: "Pwhl::Goalie" },
      ].each do |h|
        it "should set type to #{h[:result]} when roster_type is #{h[:roster_type]}" do
          current_team = create(:league_team, league: league)
          player = League::Player.create(
            name: "Jane Doe",
            api_id: "api_key",
            current_team: current_team,
            league: league,
            roster_type: h[:roster_type],
          )
          expect(player.type).to eq(h[:result])
        end
      end
    end
  end

  describe "#current_team_short_code" do
    let(:league) { create(:league, :pwhl) }
    let(:team) { create(:league_team, league: league) }
    let(:other_team) { create(:league_team, league: league) }
    let(:player) { create(:pwhl_skater, league: league, current_team: team) }

    it "is set on create" do
      expect(player.current_team_short_code).to eq(team.short_code)
    end

    it "updates when current_team changes" do
      player.update!(current_team: other_team)
      expect(player.current_team_short_code).to eq(other_team.short_code)
    end

    it "is nil when current_team is nil" do
      player.update!(current_team: nil)
      expect(player.current_team_short_code).to be_nil
    end
  end
end
