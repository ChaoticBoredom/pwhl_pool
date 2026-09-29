class Draft < ApplicationRecord
  belongs_to :pool
  has_many :draft_picks, class_name: "Draft::Pick", dependent: :destroy
  has_many :draft_roster_slots, class_name: "Draft::RosterSlot", dependent: :destroy

  validates :current_pick_number, numericality: { equal_to: 0 }, if: :pending?
  validates :current_pick_number, numericality: { greater_than: 0 }, unless: :pending?

  validate :team_order_matches_pool_teams
  validate :pool_is_draft_type

  enum :state, {
    pending: 0,
    in_progress: 100,
    paused: 200,
    completed: 300,
  }

  enum :pick_order_strategy, {
    snake: 100,
    fixed: 200,
  }

  scope :scheduled, -> { pending.where.not(start_at: nil) }

  def scheduled?
    pending? && start_at.present?
  end

  private

  def team_order_matches_pool_teams
    return if pool.nil?
    return if team_order.to_a.sort == pool.pool_teams.ids.sort

    errors.add(:team_order, "must include exactly the pool's teams")
  end

  def pool_is_draft_type
    return if pool.nil?
    return if pool.pool_type_draft?

    errors.add(:pool, "must by a draft-style pool")
  end
end
