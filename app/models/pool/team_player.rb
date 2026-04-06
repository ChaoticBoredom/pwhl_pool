class Pool::TeamPlayer < ApplicationRecord
  include PlayerPositions
  attribute :scores, :json, default: -> { {} }

  belongs_to :pool
  belongs_to :pool_team, class_name: "Pool::Team"
  belongs_to :league_player, class_name: "League::Player"

  delegate :name, :current_team_id, to: :league_player

  before_validation :denormalize_fields, on: :create

  scope :current, -> { where(dropped_at: nil) }
  scope :non_current, -> { where.not(dropped_at: nil) }
  scope :for_date, ->(date) { where(added_at: ...date).where("dropped_at > ? OR dropped_at IS NULL", date) }

  def current?
    dropped_at.nil?
  end

  def score_for_today
    score_for_date(DateTime.current)
  end

  def score_for_date(date)
    scorings = get_scoring_fields
    record = league_player.records.for_date(date)
    return 0 if record.nil?

    scorings.sum do |s|
      parse_field(record[s[:field_name]]) * s[:value]
    end
  end

  def score_for_date_range(date_range, on_team = false)
    date_range = clip_date_range(date_range) if on_team
    scorings = get_scoring_fields
    fields = scorings.pluck(:field_name)
    raw_records = league_player.records.
      for_season(pool.season_id).
      for_date_range(date_range).
      pluck(*fields)

    records = raw_records.map { |r| fields.zip(r).to_h }

    scorings.sum do |s|
      records.sum { |v| parse_field(v[s[:field_name]]) } * s[:value]
    end
  end

  def score_for_season
    score_for_date_range(added_at..dropped_at)
  end

  def scores
    partial = Rails.cache.fetch("#{cache_key_with_version}/scores_upto_today", expires_at: Time.current.tomorrow.beginning_of_day) do
      {
        month_to_date: score_for_date_range(DateTime.current.all_month, true),
        week_to_date: score_for_date_range(DateTime.current.all_week, true),
        yesterday: score_for_date(1.day.ago),
      }
    end
    todays_score = score_for_date(DateTime.current)
    partial.transform_values { |v| v + todays_score }.merge(today: todays_score)
  end

  private

  def clip_date_range(date_range)
    effective_start = [date_range.begin, added_at].max
    effective_end = [date_range.end, dropped_at].compact.min

    effective_start..effective_end
  end

  def parse_field(val)
    case val
    when true then 1
    when false then 0
    when ActiveSupport::Duration then val.in_minutes.to_i
    else val.to_i
    end
  end

  def get_scoring_fields
    Rails.cache.fetch("scores/#{pool.cache_key_with_version}/#{position}", expires_in: 1.month) do
      scorings = pool.scoring.where(position: position).pluck(:field_name, :value)
      scorings.map! { |s| [:field_name, :value].zip(s).to_h }
    end
  end

  def denormalize_fields
    self.pool_id ||= pool_team.pool_id
    self.position ||= league_player.position
  end
end
