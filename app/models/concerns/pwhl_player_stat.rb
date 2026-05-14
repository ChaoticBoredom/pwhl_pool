module PwhlPlayerStat
  extend ActiveSupport::Concern

  included do
    before_validation :add_game_attributes, if: -> { league_game.present? }, on: :create

    validates :goals, :assists, :penalty_minutes, :time_on_ice, :start_time, :season_id, presence: true

    validates :league_player_id, uniqueness: { scope: :league_game_id, message: "should have one game stat per player" }

    belongs_to :league_team, class_name: "League::Team"
    belongs_to :league_game, class_name: "League::Game"
    belongs_to :league_player, class_name: "League::Player"

    scope :for_date_range, ->(date_range) { where(start_time: date_range) }
    scope :for_season, ->(season_id) { where(season_id: season_id) }

    def add_game_attributes
      self.start_time = league_game.start_time
      self.season_id = league_game.season_id
    end

    def self.for_date(date)
      where(start_time: date.all_day).first
    end
  end
end
