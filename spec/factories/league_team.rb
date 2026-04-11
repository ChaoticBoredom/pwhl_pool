FactoryBot.define do
  factory :league_team, class: "League::Team" do
    name { Faker::Team.name }
    association :league
    sequence(:api_id) { |n| "api_key_#{n}" }
    short_code { Faker::Name.initials(number: 3) }
  end
end
