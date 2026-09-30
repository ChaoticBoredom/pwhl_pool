require "rails_helper"

RSpec.describe Draft, type: :model do
  let(:pool) { create(:pool, pool_type: :draft) }

  subject(:draft) { build(:draft, pool: pool) }

  it "is invalid when the pool is not a draft-type pool" do
    pool = create(:pool, pool_type: :box_select)
    draft = build(:draft, pool: pool)

    expect(draft).to_not be_valid
  end

  describe "current_pick_number" do
    context "when draft is pending" do
      it "is valid at 0" do
        draft.current_pick_number = 0
        expect(draft).to be_valid
      end

      it "is invalid at any non-zero value" do
        draft.current_pick_number = 1
        expect(draft).to_not be_valid
      end
    end

    context "when draft is in_progress" do
      before(:each) do
        draft.state = :in_progress
      end

      it "is valid at a non-zero value" do
        draft.current_pick_number = 1
        expect(draft).to be_valid
      end

      it "is invalid at 0" do
        draft.current_pick_number = 0
        expect(draft).to_not be_valid
      end
    end
  end

  describe "team_order" do
    context "when pool has no teams" do
      it "is valid when empty" do
        draft.team_order = []
        expect(draft).to be_valid
      end
    end

    context "when pool has teams" do
      let!(:team_one) { create(:pool_team, pool: pool) }
      let!(:team_two) { create(:pool_team, pool: pool) }

      it "is valid when it exactly matches pool team ids" do
        draft.team_order = [team_one.id, team_two.id]

        expect(draft).to be_valid
      end

      it "is valid when it exactly matches pool team ids in reverse order" do
        draft.team_order = [team_two.id, team_one.id]

        expect(draft).to be_valid
      end

      it "is invalid if a pool team is missing" do
        draft.team_order = [team_one.id]

        expect(draft).to_not be_valid
      end

      it "is invalid when it includes a team not in the pool" do
        bad_team = create(:pool_team, pool: create(:pool, pool_type: :draft))
        draft.team_order = [team_one.id, team_two.id, bad_team.id]

        expect(draft).to_not be_valid
      end
    end
  end

  describe "#scheduled?" do
    context "when draft is 'pending'" do
      it "is true with a start_at" do
        draft.start_at = 3.days.from_now

        expect(draft.scheduled?).to be(true)
      end

      it "is false without a start_at" do
        draft.start_at = nil
        expect(draft.scheduled?).to be(false)
      end
    end

    context "when draft is 'in_progress'" do
      before(:each) do
        draft.state = :in_progress
      end

      it "is false without a start_at" do
        draft.start_at = nil

        expect(draft.scheduled?).to be(false)
      end

      it "is false with a start_at" do
        draft.start_at = 3.days.from_now

        expect(draft.scheduled?).to be(false)
      end
    end
  end

  describe ".scheduled" do
    it "returns only pending drafts with a start_at" do
      scheduled_draft = create(:draft, start_at: 3.days.from_now)
      unscheduled_draft = create(:draft)

      expect(Draft.scheduled).to contain_exactly(scheduled_draft)
    end
  end
end
