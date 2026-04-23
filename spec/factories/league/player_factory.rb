FactoryBot.define do
  factory :league_player, class: "League::Player" do
    name { Faker::Name.name }
    sequence(:api_id) { |n| "api_key_#{n}" }
    association :league

    current_team { association(:league_team, league: league) }

    factory :pwhl_skater, class: "Pwhl::Skater" do
      position { :skater }
      association :league, :pwhl
      current_team { association(:league_team, league: league) }
    end

    factory :pwhl_goalie, class: "Pwhl::Goalie" do
      position { :goalie }
      association :league, :pwhl
      current_team { association(:league_team, league: league) }
    end
  end
end
