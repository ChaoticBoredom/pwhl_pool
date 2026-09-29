class Draft::Pick < ApplicationRecord
  belongs_to :draft
  belongs_to :pool_team, class_name: "Pool::Team"
  belongs_to :league_player, class_name: "League::Player", optional: true
  belongs_to :tentative_league_player, class_name: "League::Player", optional: true

  validates :pick_number, presence: true, uniqueness: { scope: :draft_id }
  validates :round, presnce: true, numericality: { only_integer: true, greater_than: 0 }
  validates :league_player_id, uniqueness: { scope: :draft_id }, allow_nil: true
  validates :made_at, presence: true, if: -> { league_player_id.present? }
  validates :league_player_id, presence: true, if: -> { made_at.present? }

  validate :pool_team_matches_draft_pool

  private

  def pool_team_matches_draft_pool
    return if pool_team.nil? || draft.nil?

    errors.add(:pool_team, "must belong to the same pool as the draft") if pool_team.pool_id != draft.pool_id
  end
end
