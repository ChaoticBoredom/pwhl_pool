class Pwhl::Game < League::Game
  # PWHL API ids are simple numerics, order by them by default
  default_scope { order(:api_id) }

  has_many :skater_records, class_name: "Pwhl::SkaterStat", foreign_key: "league_game_id", dependent: :destroy
  has_many :goalie_records, class_name: "Pwhl::GoalieStat", foreign_key: "league_game_id", dependent: :destroy
end
