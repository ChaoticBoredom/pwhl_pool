module Pwhl
  module StatConfig
    DEFAULT_BOXES = [
      BoxGeneration::BoxDefinition.new(name: "Forwards Box 1", position: "F", rank: 1, count: 1),
      BoxGeneration::BoxDefinition.new(name: "Forwards Box 2", position: "F", rank: 2, count: 1),
      BoxGeneration::BoxDefinition.new(name: "Forwards Box 3", position: "F", rank: 3, count: 1),
      BoxGeneration::BoxDefinition.new(name: "Forwards Box 4", position: "F", rank: 4, count: 1),
      BoxGeneration::BoxDefinition.new(name: "Forwards Box 5", position: "F", rank: 5, count: 1),
      BoxGeneration::BoxDefinition.new(name: "Defence Box 1", position: "D", rank: 1, count: 1),
      BoxGeneration::BoxDefinition.new(name: "Defence Box 2", position: "D", rank: 2, count: 1),
      BoxGeneration::BoxDefinition.new(name: "Defence Box 3", position: "D", rank: 3, count: 1),
      BoxGeneration::BoxDefinition.new(name: "Goalies Box 1", position: "G", rookie: nil, rank: 1, count: 1),
      BoxGeneration::BoxDefinition.new(name: "Rookie Forwards Box 1", position: "F", rookie: true, rank: 1, count: 1),
      BoxGeneration::BoxDefinition.new(name: "Rookie Defence Box 1", position: "D", rookie: true, rank: 1, count: 1),
    ].freeze

    DEFAULT_SCORING = {
      goalie: {
        win: 2.0,
        saves: 0.05,
        shutout: 2.0,
        penalty_minutes: 0.25,
        goals: 5.0,
        assists: 2.0,
      },
      skater: {
        goals: 2.0,
        assists: 1.0,
        penalty_minutes: 0.25,
        shots: 0.25,
        hits: 0.25,
        power_play_goals: 1.0,
        short_handed_goals: 2.0,
      },
    }.freeze

    SEASON_LABELS = {
      "8" => "2025-26 Regular Season",
      "9" => "2025-26 Playoffs",
      # "10" => "2026-27 Regular Season",
      # "DEMO" => "Demo",
    }.freeze

    POSITION_GROUPS = {
      "F" => ["F", "LW", "RW", "C"],
      "D" => ["D", "LD", "RD"],
      "G" => ["G"],
    }.freeze

    STATS = {
      goalie: [
        :goals, :assists, :goals_against, :shots_against, :penalty_minutes,
        :win, :shutout, :saves, :time_on_ice, :game_started
      ],
      skater: [
        :goals, :assists, :penalty_minutes, :shots, :hits, :time_on_ice,
        :plus_minus, :power_play_goals, :short_handed_goals, :shots_blocked,
        :faceoffs_taken, :faceoffs_won, :game_winning_goals
      ],
    }.with_indifferent_access.freeze

    SCOREABLE_STATS = {
      goalie: STATS[:goalie] - [:time_on_ice],
      skater: STATS[:skater] - [:time_on_ice],
    }.freeze

    STAT_LABELS = {
      goals: "Goals",
      assists: "Assists",
      shots:  "Shots",
      hits: "Hits",
      saves: "Saves",
      shutout: "Shutouts",
      win: "Wins",
      penalty_minutes: "PIM",
      power_play_goals: "PPG",
      short_handed_goals: "SHG",
      faceoffs_won: "Faceoffs Won",
      faceoffs_taken: "Faceoffs",
      time_on_ice: "TOI",
      plus_minus: "+/-",
      shots_against: "SA",
      goals_against: "GA",
      game_started: "Games Started",
      game_winning_goals: "GWG",
      shots_blocked: "Blocked",
    }.freeze
  end
end
