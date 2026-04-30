class League::Game < ApplicationRecord
  default_scope { order(start_time: :asc) }

  before_validation :sync_sti_type, if: -> { league_id_changed? }

  validates :api_id, :season_id, :type, :start_time, :home_team, :away_team, presence: true

  belongs_to :league
  belongs_to :home_team, class_name: "League::Team", foreign_key: "home_team_id"
  belongs_to :away_team, class_name: "League::Team", foreign_key: "away_team_id"

  scope :for_season, ->(season_id) { where(season_id: season_id) }

  enum :status, {
    scheduled: 0,
    in_progress: 10,
    pending_final: 21,
    final: 20,
  }, validate: true

  private

  def sync_sti_type
    self.type = "#{league.short_name.capitalize}::Game"
  end
end
