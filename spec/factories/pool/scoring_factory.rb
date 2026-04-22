FactoryBot.define do
  factory :pool_scoring, class: "Pool::Scoring" do
    association :pool
    field_name { "goals" }
    position   { :skater }
    value      { 1.0 }

    trait :skater do
      position { :skater }
    end

    trait :goals do
      field_name { "goals" }
      value      { 3.0 }
    end

    trait :assists do
      field_name { "assists" }
      value      { 2.0 }
    end

    trait :shots do
      field_name { "shots" }
      value      { 0.5 }
    end

    trait :shots_blocked do
      field_name { "shots_blocked" }
      value      { 0.5 }
    end

    trait :hits do
      field_name { "hits" }
      value      { 0.25 }
    end

    trait :power_play_goals do
      field_name { "power_play_goals" }
      value      { 1.0 }
    end

    trait :short_handed_goals do
      field_name { "short_handed_goals" }
      value      { 2.0 }
    end

    trait :goalie do
      position { :goalie }
    end

    trait :saves do
      field_name { "saves" }
      value      { 0.25 }
    end

    trait :wins do
      field_name { "win" }
      value      { 5.0 }
    end

    trait :shutouts do
      field_name { "shutout" }
      value      { 3.0 }
    end

    trait :goals_against do
      field_name { "goals_against" }
      value      { -1.0 }
    end
  end
end
