FactoryBot.define do
  factory :league_player, class: "League::Player" do
    transient do
      league { raise ArgumentError, "Must pass league: explicitly to :league_player factory" }
    end

    after(:build) do |player, evaluator|
      player.league = evaluator.league
    end

    name { Faker::Name.name }
    sequence(:api_id) { |n| "api_key_#{n}" }

    current_team { association(:league_team, league: league) }

    factory :pwhl_skater, class: "Pwhl::Skater" do
      position { :skater }
    end

    factory :pwhl_goalie, class: "Pwhl::Goalie" do
      position { :goalie }
    end
  end
end
