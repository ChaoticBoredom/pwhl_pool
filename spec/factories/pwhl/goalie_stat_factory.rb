FactoryBot.define do
  factory :pwhl_goalie_stat, class: "Pwhl::GoalieStat" do
    association :league_game, factory: %i[league_game final]
    association :league_player
    association :league_team

    goals         { 0 }
    assists       { 0 }
    saves         { 0 }
    shots_against { 0 }
    goals_against { 0 }
    shutout       { false }
    win           { false }
    penalty_minutes { 0.minutes }
    time_on_ice     { 60.minutes }

    trait :shutout_win do
      saves         { 28 }
      shots_against { 28 }
      goals_against { 0 }
      shutout       { true }
      win           { true }
    end

    trait :win do
      saves         { 25 }
      shots_against { 28 }
      goals_against { 3 }
      win           { true }
    end

    trait :loss do
      saves         { 20 }
      shots_against { 25 }
      goals_against { 5 }
      win           { false }
    end
  end
end
