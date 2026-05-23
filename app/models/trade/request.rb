class Trade::Request < ApplicationRecord
  belongs_to :pool_team, class_name: "Pool::Team"
  belongs_to :requested_by, class_name: "User"
  belongs_to :decided_by, class_name: "User"
  belongs_to :league_player, class_name: "League::Player"
  belongs_to :pool_box, class_name: "Pool::Box", optional: true

  enum :action, {
    add: 100,
    drop: 200,
  }, prefix: :trade_action

  enum :status, {
    pending: 0,
    approved: 100,
    auto_approved: 150,
    rejected: 200,
    auto_rejected: 250,
    cancelled: 300,
    auto_cancelled: 350,
  }, prefix: :trade_status

  HUMAN_DECIDED_STATUSES = %w[approved rejected cancelled].freeze
  SYSTEM_DECIDED_STATUSES = %w[auto_approved auto_rejected auto_cancelled].freeze

  validates :action, :status, :requested_at, presence: true
  validates :pool_box,
    presence: true,
    if: -> { trade_action_add? && pool_team.pool.box_select? }
  validates :rejected_reason, presence: true, if: :trade_status_rejected?
  validates :status, inclusion: { in: [0] }, on: :create
  validates :decided_by, presence: true, if: -> { status.in?(HUMAN_DECIDED_STATUSES) }
  validates :decided_by, absence: true, if: -> { status.in?(SYSTEM_DECIDED_STATUSES) }

  scope :any_approved, -> { where("status >= 100 AND status < 200") }
  scope :any_rejected, -> { where("status >= 200 AND status < 300") }
  scope :any_cancelled, -> { where("status >= 300") }
  scope :resolved, -> { where("status >= 100") }

  scope :for_group, ->(group_id) { where(request_group_id: group_id) }
  scope :pending_for_player,  ->(player_id) { trade_status_pending.where(league_player_id: player_id) }

  def decide!(status, decided_at: Time.current, decided_by: nil, backdated_to: nil, rejected_reason: nil)
    update!(
      status: status,
      decided_at: decided_at,
      decided_by: decided_by,
      backdated_to: backdated_to,
      rejected_reason: rejected_reason
    )
  end
end
