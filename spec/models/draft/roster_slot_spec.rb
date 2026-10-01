require "rails_helper"

RSpec.describe Draft::RosterSlot, type: :model do
  it_behaves_like "PlayerPositionTypes"

  it { is_expected.to validate_presence_of(:count) }
  it { is_expected.to validate_numericality_of(:count).only_integer.is_greater_than_or_equal_to(0) }

  describe "position_type uniqueness" do
    let(:draft) { create(:draft) }

    it "is invalid with a duplicate position_type for the same draft" do
      create(:draft_roster_slot, draft: draft, position_type: :forward)
      dupe = build(:draft_roster_slot, draft: draft, position_type: :forward)

      expect(dupe).to_not be_valid
    end

    it "is valid with the same position_type for a different draft" do
      create(:draft_roster_slot, draft: draft, position_type: :forward)
      other_slot = build(:draft_roster_slot, draft: create(:draft), position_type: :forward)

      expect(other_slot).to be_valid
    end
  end
end
