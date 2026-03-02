class Pwhl::Skater < League::Player
  has_many :records, class_name: "Pwhl::SkaterStat", foreign_key: "league_player_id", dependent: :destroy
end
