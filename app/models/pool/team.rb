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

  def score_for_date(date)
    pss = PlayerScoringService.new(pool.scoring, pool)
    players = pool_team_players.for_date(date).includes(:league_player)

    players.sum { |p| pss.score_for_date(date, p.league_player) }
  end

  def score_for_date_range(date_range)
    pss = PlayerScoringService.new(pool.scoring, pool)
    pool_team_players.
      includes(:league_player).
      map { |pt| pss.score_for_pool_date_range(date_range, pt.league_player) }.sum
  end

  def total_score
    pss = PlayerScoringService.new(pool.scoring, pool)
    dropped_scores = Rails.cache.fetch("#{cache_key_with_version}/partial_total_dropped", expires_in: 24.hours) do
      players = pool_team_players.includes(:pool, league_player: :records).non_current

      players.map { |p| p.score_for_pool(pss) }.sum
    end

    players = pool_team_players.includes(:pool, league_player: :records).current

    dropped_scores + players.map { |p| p.score_for_pool(pss) }.sum
  end
end
