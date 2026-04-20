FactoryBot.define do
  factory :league_game, class: "League::Game", traits: [:scheduled]  do
    sequence(:api_id) { |n| "api_key_#{n}" }
    season_id { 2 }

    transient do
      league { association(:league) }
    end
    association :home_team, factory: :league_team
  end


  trait :scheduled do
    start_time { 1.day.from_now }
    status { "scheduled" }
  end

  trait :in_progress do
    start_time { 20.minutes.ago }
    status { "in_progress" }
  end

  trait :final do
    start_time { 4.hours.ago }
    status { "final" }
  end
end
