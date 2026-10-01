require "rails_helper"

RSpec.describe Draft::Pick, type: :model do
  subject { create(:draft_pick) }

  it { is_expected.to validate_presence_of(:pick_number) }
  it { is_expected.to validate_uniqueness_of(:pick_number).scoped_to(:draft_id) }
  it { is_expected.to validate_presence_of(:round) }
  it { is_expected.to validate_numericality_of(:round).only_integer.is_greater_than(0) }

  describe "league_player_id uniqueness" do
    let(:draft) { create(:draft) }
    let(:pool_team) { create(:pool_team, pool: draft.pool) }
    let(:league_player) { create(:pwhl_skater, league: draft.pool.league) }

    subject { create(:draft_pick, :pick_made, draft: draft, league_player: league_player) }

    it { is_expected.to validate_uniqueness_of(:league_player_id).
      scoped_to(:draft_id).
      allow_nil.
      ignoring_case_sensitivity }
  end

  describe "made_at and league_player_id" do
    let(:skater) { create(:pwhl_skater, league: pick.draft.pool.league) }
    let(:league) { pick.draft.pool.league }

    subject(:pick) { build(:draft_pick) }

    it "is invalid when made_at is set without a league_player" do
      pick.made_at = Time.current

      expect(pick).to_not be_valid
    end

    it "is invalid when a league_player is set without made_at" do
      pick.league_player = skater

      expect(pick).to_not be_valid
    end

    it "is valid when made_at and league_player are set together" do
      pick.league_player = skater
      pick.made_at = Time.current

      expect(pick).to be_valid
    end
  end

  it "is invalid when 'pool_team' belongs to a different pool than the draft" do
    pool = create(:pool, pool_type: :draft)
    pick = build(:draft_pick, pool_team: create(:pool_team, pool: pool))

    expect(pick).to_not be_valid
  end
end
