class League::Player < ApplicationRecord
  include PlayerPositions
  before_save :sync_sti_type, if: -> { position_changed? || league_id_changed? }

  belongs_to :league
  belongs_to :current_team, class_name: "League::Team"

  private

  def sync_sti_type
    prefix = league.short_name.capitalize
    suffix = position.capitalize
    self.type = [prefix, suffix].compact.join("::")
  end
end
