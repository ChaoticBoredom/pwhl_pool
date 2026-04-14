class League::Player < ApplicationRecord
  include PlayerPositions
  include PlayerScoring
  before_validation :sync_sti_type, if: -> { position_changed? || league_id_changed? }

  validates :name, :type, :api_id, presence: true

  belongs_to :league
  belongs_to :current_team, class_name: "League::Team"

  private

  def sync_sti_type
    prefix = league.short_name.capitalize
    suffix = position.capitalize
    self.type = [prefix, suffix].compact.join("::")
  end
end
