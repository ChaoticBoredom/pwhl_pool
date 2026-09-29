FactoryBot.define do
  factory :draft_pick, class: "Draft::Pick" do
    association :draft
    pool_team { create(:pool_team, pool: draft.pool) }
    sequence(:pick_name) { |n| n }
    round { 1 }

    trait :pick_made do
      association :league_player, factory: :pwhl_skater
      made_at { Time.current }
    end

    trait :tentative_pick do
      association :tentative_league_player, factory: :pwhl_skater
    end
  end
end
