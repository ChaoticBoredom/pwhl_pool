class Pwhl::SkaterStat < ApplicationRecord
  include PwhlPlayerStat

  validates :shots, :hits, :plus_minus, :power_play_goals, :short_handed_goals, :shots_blocked, :faceoffs_taken, :faceoffs_won, presence: true
end
