class League::Player < ApplicationRecord
  before_create :set_type

  belongs_to :league
  belongs_to :current_team, class_name: "League::Team"

  enum :position, {
    skater: 100,
    goalie: 200,
  }

  private

  def set_type
    prefix = case league.short_name
    when "PWHL"
      "Pwhl"
    end

    suffix = case position
    when "skater"
      "Skater"
    when "goalie"
      "Goalie"
    end

    self.type = [prefix, suffix].join("::")
  end
end
