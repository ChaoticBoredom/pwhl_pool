FactoryBot.define do
  factory :pwhl_skater_stat, class: "Pwhl::SkaterStat" do
    transient do
      league { raise ArgumentError, "Must pass league: explicitly to :pwhl_skater_stat factory" }
    end

    association :league_game, factory: %i[league_game final]
    association :league_team

    after(:build) do |stat, evaluator|
      stat.league_player = evaluator.league_player || build(:pwhl_skater, league: evaluator.league)
      stat.league_game.league = evaluator.league
    end

    goals             { 0 }
    assists           { 0 }
    shots             { 0 }
    shots_blocked     { 0 }
    hits              { 0 }
    plus_minus        { 0 }
    power_play_goals  { 0 }
    short_handed_goals { 0 }
    faceoffs_taken    { 0 }
    faceoffs_won      { 0 }
    penalty_minutes   { 0.minutes }
    time_on_ice       { 15.minutes }

    trait :scorer do
      goals   { 1 }
      assists { 1 }
      shots   { 3 }
      plus_minus { 2 }
    end

    trait :enforcer do
      plus_minus      { -2 }
      hits            { 5 }
      shots_blocked   { 2 }
      penalty_minutes { 4.minutes }
    end
  end
end
