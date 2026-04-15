class Pool::TeamPlayer < ApplicationRecord
  include PlayerPositions
  include PlayerScoring
  belongs_to :pool
  belongs_to :pool_team, class_name: "Pool::Team"
  belongs_to :league_player, class_name: "League::Player"

  validates :added_at, presence: true

  delegate :name, :current_team_id, :records, to: :league_player

  before_validation :denormalize_fields, on: :create

  scope :current, -> { where(dropped_at: nil) }
  scope :non_current, -> { where.not(dropped_at: nil) }
  scope :for_date, ->(date) { where(added_at: ...date).where("dropped_at > ? OR dropped_at IS NULL", date) }

  def current?
    dropped_at.nil?
  end

  def score_for_pool
    cache_key = "#{cache_key_with_version}/#{updated_at.to_i}"
    expiry = current? ? Time.current.tomorrow.beginning_of_day : nil
    Rails.cache.fetch(cache_key, expires_at: expiry) do
      score_for_date_range(clip_date_range(pool.start_end_range))
    end
  end

  def pool_to_use
    pool
  end

  private

  def clip_date_range(date_range)
    effective_start = [date_range.begin, added_at].max
    effective_end = [date_range.end, dropped_at].compact.min

    effective_start..effective_end
  end

  def denormalize_fields
    self.pool_id ||= pool_team.pool_id
    self.position ||= league_player.position
  end
end
