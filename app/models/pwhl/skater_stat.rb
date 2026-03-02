class Pwhl::SkaterStat < ApplicationRecord
  validates :goals, :assists, :penalty_minutes, :shots, :hits, :time_on_ice, :plus_minus, :power_play_goals, :short_handed_goals, :shots_blocked, :faceoffs_taken, :faceoffs_won, presence: true

  validates :league_player_id, uniqueness: { scope: :league_game_id, message: "should have one game stat per game" }

  belongs_to :league_team, class_name: "League::Team"
  belongs_to :league_game, class_name: "League::Game"
  belongs_to :league_player, class_name: "League::Player"
end
