class Pool::Scoring < ApplicationRecord
  include PlayerRosterTypes

  belongs_to :pool

  validates :field_name, :value, presence: true

  validates :field_name, uniqueness: { scope: [:pool_id, :roster_type], message: "should have one scoring value per field per pool" }
end
