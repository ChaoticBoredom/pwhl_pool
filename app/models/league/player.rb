class League::Player < ApplicationRecord
  include PlayerRosterTypes
  before_validation :sync_sti_type, if: -> { roster_type_changed? || league_id_changed? }
  before_save :sync_current_team_short_code, if: :current_team_id_changed?

  validates :name, :type, :api_id, presence: true

  belongs_to :league
  belongs_to :current_team, class_name: "League::Team", optional: true

  private

  def sync_sti_type
    prefix = league.short_name.capitalize
    suffix = roster_type.capitalize
    self.type = [prefix, suffix].compact.join("::")
  end

  def sync_current_team_short_code
    self.current_team_short_code = current_team&.short_code
  end
end
