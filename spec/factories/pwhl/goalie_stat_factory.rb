FactoryBot.define do
  factory :pwhl_goalie_stat, class: "Pwhl::GoalieStat" do
    transient do
      league { raise ArgumentError, "Must pass league: explicitly to :pwhl_goalie_stat factory" }
    end

    after(:build) do |stat, evaluator|
      stat.league_player = evaluator.league_player || build(:pwhl_skater, league: evaluator.league)
      stat.league_game = evaluator.league_game || build(:league_game, :final, league: evaluator.league)
      stat.league_team = evaluator.league_team || stat.league_player.current_team
    end

    goals         { 0 }
    assists       { 0 }
    saves         { 0 }
    shots_against { 0 }
    goals_against { 0 }
    shutout       { false }
    win           { false }
    game_started  { true }
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

    trait :relief_game do
      saves         { 10 }
      shots_against { 12 }
      goals_against { 2 }
      win           { false }
      game_started  { false }
    end
  end
end
