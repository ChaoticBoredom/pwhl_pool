class Pwhl::GoalieStat < ApplicationRecord
  include PwhlPlayerStat

  validates :goals_against, :shots_against, :saves, presence: true

  validates :win, :shutout, inclusion: { in: [true, false] }
end
