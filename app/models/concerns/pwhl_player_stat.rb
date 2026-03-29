module PwhlPlayerStat
  extend ActiveSupport::Concern

  included do
    validates :goals, :assists, :penalty_minutes, :time_on_ice, presence: true


    validates :league_player_id, uniqueness: { scope: :league_game_id, message: "should have one game stat per player" }

    belongs_to :league_team, class_name: "League::Team"
    belongs_to :league_game, class_name: "League::Game"
    belongs_to :league_player, class_name: "League::Player"

    def self.for_date(date)
      joins(:league_game).where(league_game: { start_time: date.all_day }).first
    end
  end
end
