require "rails_helper"

RSpec.describe Pool::TeamPlayer, type: :model do
  let(:league) { create(:league, :pwhl) }
  let(:pool_team) { create(:pool_team) }
  let(:league_player) { create(:pwhl_skater, league: league) }

  subject(:team_player) { create(:pool_team_player, pool_team: pool_team, league_player: league_player) }

  it { should belong_to(:pool) }
  it { should belong_to(:pool_team).class_name("Pool::Team") }
  it { should belong_to(:league_player).class_name("League::Player") }
  it { should belong_to(:pool_box).class_name("Pool::Box") }

  it { is_expected.to validate_presence_of(:added_at) }

  describe "dropped_at validation" do
    let(:pool_team) { create(:pool_team) }
    let(:added_at) { 3.days.ago }

    subject(:team_player) do
      build(:pool_team_player,
        pool_team: pool_team,
        league_player: league_player,
        added_at: added_at,
        dropped_at: dropped_at
      )
    end

    context "when dropped_at is nil" do
      let(:dropped_at) { nil }

      it "is valid" do
        expect(team_player).to be_valid
      end
    end

    context "when dropped_at is after added_at" do
      let(:dropped_at) { 1.day.ago }

      it "is valid" do
        expect(team_player).to be_valid
      end
    end

    context "when dropped_at equals added_at" do
      let(:dropped_at) { added_at }

      it "is valid" do
        expect(team_player).to be_valid
      end
    end

    context "when dropped_at is before added_at" do
      let(:dropped_at) { 5.days.ago }

      it "is invalid" do
        expect(team_player).to_not be_valid
      end

      it "adds an error on dropped_at" do
        team_player.valid?
        expect(team_player.errors[:dropped_at]).to include("can't be before added_at")
      end
    end
  end

  describe "#current?" do
    let(:pool_team) { create(:pool_team) }

    it "returns true when dropped_at is nil" do
      team_player = build(:pool_team_player, pool_team: pool_team, league_player: league_player, dropped_at: nil)
      expect(team_player.current?).to be(true)
    end

    it "returns false when dropped_at is present" do
      team_player = build(:pool_team_player, pool_team: pool_team, league_player: league_player, added_at: 3.days.ago, dropped_at: 1.day.ago)
      expect(team_player.current?).to be(false)
    end
  end
end
