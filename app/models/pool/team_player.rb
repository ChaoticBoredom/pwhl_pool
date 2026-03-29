class Pool::TeamPlayer < ApplicationRecord
  belongs_to :pool_team, class_name: "Pool::Team"
  belongs_to :league_player, class_name: "League::Player"

  scope :current, -> { where(dropped_at: nil) }
  scope :for_date, ->(date) { where(added_at: ...date).where("dropped_at > ? OR dropped_at IS NULL", date) }

  def score_for_date(date)
    scorings = pool_team.pool.scoring.where(position: league_player.position)
    record = league_player.records.for_date(date)
    scorings.sum do |s|
      record_value = case record[s.field_name]
      when true then 1
      when false then 0
      else record[s.field_name].to_i
      end
      record_value * s.value
    end
  end
end
