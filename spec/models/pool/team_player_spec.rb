require "rails_helper"

RSpec.describe Pool::TeamPlayer, type: :model do
  let(:league) { create(:league, :pwhl) }
  let(:pool_team) { create(:pool_team) }
  let(:league_player) { create(:pwhl_skater, league: league) }
  let(:pool_box) { create(:pool_box, pool: pool_team.pool) }

  subject(:team_player) do
    create(:pool_team_player,
      pool_team: pool_team,
      league_player: league_player,
      pool_box: pool_box
    )
  end

  it { should belong_to(:pool) }
  it { should belong_to(:pool_team).class_name("Pool::Team") }
  it { should belong_to(:league_player).class_name("League::Player") }

  it { is_expected.to validate_presence_of(:added_at) }

  describe "pool_box presence" do
    let(:pool) { create(:pool, pool_type: pool_type) }
    let(:pool_team) { create(:pool_team, pool: pool) }

    subject(:team_player) do
      build(:pool_team_player,
        pool_team: pool_team,
        league_player: league_player,
        pool_box: pool_box
      )
    end

    context "when the pool is box_select" do
      let(:pool_type) { :box_select }

      context "with a pool_box" do
        let(:pool_box) { create(:pool_box, pool: pool) }

        it "is valid" do
          expect(team_player).to be_valid
        end
      end

      context "without a pool_box" do
        let(:pool_box) { nil }

        it "is invalid" do
          expect(team_player).to_not be_valid
        end

        it "adds an error on pool_box" do
          team_player.valid?
          expect(team_player.errors[:pool_box]).to include("can't be blank")
        end
      end
    end

    context "when the pool is draft" do
      let(:pool_type) { :draft }
      let(:pool_box) { nil }

      it "is valid without a pool_box" do
        expect(team_player).to be_valid
      end
    end
  end

  describe "pool_box matches pool" do
    let(:pool) { create(:pool, pool_type: :box_select) }
    let(:pool_team) { create(:pool_team, pool: pool) }

    subject(:team_player) do
      build(:pool_team_player,
        pool_team: pool_team,
        league_player: league_player,
        pool_box: pool_box
      )
    end

    context "when the pool_box belongs to the same pool" do
      let(:pool_box) { create(:pool_box, pool: pool) }

      it "is valid" do
        expect(team_player).to be_valid
      end
    end

    context "when the pool_box belongs to a different pool" do
      let(:pool_box) { create(:pool_box) }

      it "is invalid" do
        expect(team_player).to_not be_valid
      end

      it "adds an error on pool_box" do
        team_player.valid?
        expect(team_player.errors[:pool_box]).to include("must belong to the same pool")
      end
    end
  end

  describe "dropped_at validation" do
    let(:pool_team) { create(:pool_team) }
    let(:pool_box) { create(:pool_box, pool: pool_team.pool) }
    let(:added_at) { 3.days.ago }

    subject(:team_player) do
      build(:pool_team_player,
        pool_team: pool_team,
        league_player: league_player,
        pool_box: pool_box,
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
