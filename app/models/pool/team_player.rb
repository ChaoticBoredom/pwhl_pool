class Pool::TeamPlayer < ApplicationRecord
  include PlayerRosterTypes
  belongs_to :pool
  belongs_to :pool_team, class_name: "Pool::Team"
  belongs_to :league_player, class_name: "League::Player"
  belongs_to :pool_box, class_name: "Pool::Box"

  validates :added_at, presence: true
  validate :dropped_at_after_added_at

  delegate :name, :current_team_id, :records, to: :league_player

  before_validation :denormalize_fields, on: :create

  scope :current, -> { where(dropped_at: nil) }
  scope :non_current, -> { where.not(dropped_at: nil) }
  scope :for_date, ->(date) do
    where(added_at: ...date).
    where("dropped_at > ? OR dropped_at IS NULL", date)
  end

  def current?
    dropped_at.nil?
  end

  def active_range
    added_at..dropped_at
  end

  def self.added_at_by_team_and_player(pool_team_ids)
    where(pool_team_id: pool_team_ids, dropped_at: nil).
      pluck(:pool_team_id, :league_player_id, :added_at).
      each_with_object({}) { |(team_id, player_id, added_at), h| h[[team_id, player_id]] = added_at }
  end

  private

  def denormalize_fields
    self.pool_id ||= pool_team.pool_id
    self.roster_type ||= league_player.roster_type
  end

  def dropped_at_after_added_at
    return if dropped_at.nil?

    errors.add(:dropped_at, "can't be before added_at") if dropped_at < added_at
  end
end
