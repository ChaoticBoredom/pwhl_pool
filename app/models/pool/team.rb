class Pool::Team < ApplicationRecord
  attribute :total_score, :float, default: 0

  belongs_to :user
  # Lets us call `.owner` on the team seamlessly
  belongs_to :owner, class_name: "User", foreign_key: "user_id"
  belongs_to :pool

  validates :team_name, presence: true
  validates :user_id, uniqueness: { scope: :pool_id, message: "only one team per owner per pool"}

  has_many :pool_team_players, class_name: "Pool::TeamPlayer", foreign_key: "pool_team_id", dependent: :destroy
  has_many :league_players, through: :pool_team_players

  def current_team
    pool_team_players.includes(:league_player).current
  end

  def previous_team
    pool_team_players.includes(:league_player).non_current
  end

  def score_for_date(date)
    players = pool_team_players.for_date(date)

    players.sum { |p| p.score_for_date(date) }
  end

  def total_score
    dropped_scores = Rails.cache.fetch("#{cache_key_with_version}/partial_total_dropped", expires_in: 24.hours) do
      players = pool_team_players.includes(:pool, :league_player).non_current

      players.map(&:score_for_pool).sum
    end

    players = pool_team_players.includes(:pool, :league_player).current

    dropped_scores + players.map(&:score_for_pool).sum
  end
end
