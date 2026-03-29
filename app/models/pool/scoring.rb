class Pool::Scoring < ApplicationRecord
  include PlayerPositions

  belongs_to :pool

  validates :field_name, :value, presence: true

  validates :field_name, uniqueness: { scope: [:pool_id, :position], message: "should have one scoring value per field per pool" }

  scope :goalie_scoring, -> { where("field_name LIKE ? ESCAPE '^'", "goalie^_%") }
  scope :skater_scoring, -> { where("field_name LIKE ? ESCAPE '^'", "skater^_%") }
end
