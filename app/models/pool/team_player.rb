class Pool::TeamPlayer < ApplicationRecord
  belongs_to :pool_team, class_name: "Pool::Team"
  belongs_to :league_player, class_name: "League::Player"

  scope :current, -> { where(dropped_at: nil) }
  scope :for_date, ->(date) { where(added_at: ...date).where("dropped_at > ? OR dropped_at IS NULL", date) }

  def current?
    dropped_at.nil?
  end

  def score_for_date(date)
    scorings = pool_team.pool.scoring.where(position: league_player.position)
    record = league_player.records.for_date(date)
    return 0 if record.nil?

    scorings.sum do |s|
      record_value = case record[s.field_name]
      when true then 1
      when false then 0
      else record[s.field_name].to_i
      end
      record_value * s.value
    end
  end

  def score_for_season
    records = league_player.records.for_date_range(added_at, dropped_at)
    scorings = pool_team.pool.scoring.where(position: league_player.position)

    scorings.sum do |s|
      t = records.pluck(s.field_name).sum do |v|
        case v
        when true then 1
        when false then 0
        when ->(vv) { vv.respond_to?(:in_minutes) }
          v.in_minutes.to_i
        else
          v.to_i
        end
      end
      t * s.value
    end
  end
end
