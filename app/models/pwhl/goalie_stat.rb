class Pwhl::GoalieStat < ApplicationRecord
  validates :goals, :assists, :goals_against, :shots_against, :penalty_minutes, :win, :shutout, :saves, :time_on_ice, presence: true

  validates :league_player_id, uniqueness: { scope: :league_game_id, message: "should have one game stat per player" }

  belongs_to :league_team, class_name: "League::Team"
  belongs_to :league_game, class_name: "League::Game"
  belongs_to :league_player, class_name: "League::Player"
end
