class Pwhl::Goalie < League::Player
  has_many :records, class_name: "Pwhl::GoalieStat", foreign_key: "league_player_id", dependent: :destroy
end
