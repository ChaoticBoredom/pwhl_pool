class Pool::Team < ApplicationRecord
  belongs_to :user
  belongs_to :pool

  has_many :pool_team_players, class_name: "Pool::TeamPlayer", foreign_key: "pool_team_id"
  has_many :league_players, through: :pool_team_players

  def score_for_date(date)
    players = pool_team_players.for_date(date)

    players.sum { |p| p.score_for_date(date) }
  end

  def total_score
    players = pool_team_players

    players.map(&:score_for_season).sum
  end
end
