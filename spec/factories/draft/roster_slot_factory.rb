FactoryBot.define do
  factory :draft_roster_slot, class: "Draft::RosterSlot" do
    association :draft
    position_type { :forward }
    count { 3 }
  end
end
