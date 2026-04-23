class Pool::TeamPlayer < ApplicationRecord
  include PlayerPositions
  belongs_to :pool
  belongs_to :pool_team, class_name: "Pool::Team"
  belongs_to :league_player, class_name: "League::Player"

  validates :added_at, presence: true

  delegate :name, :current_team_id, :records, to: :league_player

  before_validation :denormalize_fields, on: :create

  scope :current, -> { where(dropped_at: nil) }
  scope :non_current, -> { where.not(dropped_at: nil) }
  scope :for_date, ->(date) { where(added_at: ...date).
                              where("dropped_at > ? OR dropped_at IS NULL", date) }

  def current?
    dropped_at.nil?
  end

  private

  def denormalize_fields
    self.pool_id ||= pool_team.pool_id
    self.position ||= league_player.position
  end
end
