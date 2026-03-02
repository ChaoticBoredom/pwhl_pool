class League::Game < ApplicationRecord
  before_validation :set_type, on: :create

  validates :api_id, :season_id, :type, :date, :home_team, :away_team, :status, presence: true

  belongs_to :league
  belongs_to :home_team, class_name: "League::Team", foreign_key: "home_team_id"
  belongs_to :away_team, class_name: "League::Team", foreign_key: "away_team_id"

  enum :status, {
    scheduled: 0,
    in_progress: 10,
    final: 20,
  }

  private

  def set_type
    self.type = case league.short_name
    when "PWHL"
      "Pwhl::Game"
    end
  end
end
