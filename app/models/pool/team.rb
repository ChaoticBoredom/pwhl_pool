class Pool::Team < ApplicationRecord
  belongs_to :user
  # Lets us call `.owner` on the team seamlessly
  belongs_to :owner, class_name: "User", foreign_key: "user_id"
  belongs_to :pool

  validates :team_name, presence: true
  validates :user_id, uniqueness: { scope: :pool_id, message: "only one team per owner per pool" }

  has_many :pool_team_players, class_name: "Pool::TeamPlayer", foreign_key: "pool_team_id", dependent: :destroy
  has_many :league_players, through: :pool_team_players

  def current_team
    pool_team_players.includes(league_player: :current_team).current
  end

  def previous_team
    pool_team_players.includes(league_player: :current_team).non_current
  end

  def total_score
    pss = PlayerScoringService.new(pool.scoring, pool)

    scores = pss.bulk_team_scores([self])
    scores[id] || 0.0
  end
end
