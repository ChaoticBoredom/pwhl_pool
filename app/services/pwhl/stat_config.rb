module Pwhl
  module StatConfig
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
