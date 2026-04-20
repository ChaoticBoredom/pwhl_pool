FactoryBot.define do
  factory :league_player, class: "League::Player" do
    name { Faker::Name.name }
    sequence(:api_id) { |n| "api_key_#{n}" }
    association :league
    current_team { create(:league_team, league: league) }
  end
end
