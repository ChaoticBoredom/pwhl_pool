class Draft::RosterSlot < ApplicationRecord
  include PlayerPositionTypes

  belongs_to :draft

  validates :count, presence: true, numericality: {
    only_integer: true,
    greater_than_or_equal_to: 0
  }
  validates :position_type uniqueness: {
    scope: :draft_id,
    message: "should have one roster slot per position type per draft"
  }
end
