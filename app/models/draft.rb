class Draft < ApplicationRecord
  MINIMUM_SCHEDULED_LEAD_TIME = 10.minutes.freeze

  belongs_to :pool
  has_many :draft_picks, class_name: "Draft::Pick", dependent: :destroy
  has_many :draft_roster_slots, class_name: "Draft::RosterSlot", dependent: :destroy

  validates :current_pick_number, numericality: { equal_to: 0 }, if: :not_started?
  validates :current_pick_number, numericality: { greater_than: 0 }, if: :started?
  validates :start_at, presence: true, if: :scheduled?

  validate :start_at_allows_lead_time, if: :scheduled?
  validate :team_order_matches_pool_teams
  validate :pool_is_draft_type

  enum :state, {
    pending: 0,
    scheduled: 100,
    in_progress: 200,
    paused: 300,
    completed: 999,
  }

  enum :pick_order_strategy, {
    snake: 100,
    fixed: 200,
  }

  def not_started?
    pending? || scheduled?
  end

  def started?
    !not_started?
  end

  private

  def start_at_allows_lead_time
    return unless will_save_change_to_state? || will_save_change_to_start_at?
    return if start_at.nil?
    return if start_at >= MINIMUM_SCHEDULED_LEAD_TIME.from_now

    errors.add(:start_at, "must be at least #{MINIMUM_SCHEDULED_LEAD_TIME.inspect} from now")
  end

  def team_order_matches_pool_teams
    return if pool.nil?

    order = team_order.to_a
    pool_team_ids = pool.pool_teams.ids

    errors.add(:team_order, "must not contain duplicates") if order.uniq.size != order.size
    errors.add(:team_order, "must only include teams in the pool") if (order - pool_team_ids).any?
    errors.add(:team_order, "must include every team in the pool") if started? && (pool_team_ids - order).any?
  end

  def pool_is_draft_type
    return if pool.nil?
    return if pool.draft?

    errors.add(:pool, "must be a draft-style pool")
  end
end
