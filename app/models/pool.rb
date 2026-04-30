class Pool < ApplicationRecord
  validates :name, :pool_type, presence: true
  validates :reference_season_id, exclusion: {
    in:      ->(pool) { [pool.season_id] },
    message: "must differ from season_id",
    allow_nil: true,
  }
  validates :trades_allowed, :trades_require_approval, inclusion: { in: [true, false] }

  belongs_to :league
  belongs_to :admin, class_name: "User"

  has_many :scoring, class_name: "Pool::Scoring"
  has_many :pool_teams, class_name: "Pool::Team"
  has_many :pool_boxes, class_name: "Pool::Box"
  has_many :pool_trade_windows, class_name: "Pool::TradeWindow"

  enum :pool_type, {
    box_select: 100,
    draft: 200,
  }

  def display_season_id
    reference_season_id.presence || season_id
  end

  def using_reference_season?
    reference_season_id.present?
  end

  def start_end_range
    Rails.cache.fetch("#{cache_key_with_version}/start_end_range", expires_in: pool_cache_ttl) do
      times = League::Game.
        where(league_id: league_id, season_id: season_id).
        pluck(:start_time).minmax

      if times.any?
        times.min.beginning_of_day..times.max.end_of_day
      else
        created_at.beginning_of_day..1.year.from_now.end_of_day
      end
    end
  end

  def trading_allowed_now?
    return false unless trades_allowed?
    return false if league.games_started?

    pool_trade_windows.none? || pool_trade_windows.current.exists?
  end

  private

  def pool_cache_ttl
    League::Game.exists?(league_id: league_id, season_id: season_id) ? 3.days : 1.hour
  end
end
