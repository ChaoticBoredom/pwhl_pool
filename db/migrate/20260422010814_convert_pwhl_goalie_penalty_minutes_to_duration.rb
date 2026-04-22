class ConvertPwhlGoaliePenaltyMinutesToDuration < ActiveRecord::Migration[8.1]
  def change
    change_column :pwhl_goalie_stats, :penalty_minutes, :interval,
      using: "penalty_minutes * INTERVAL '1 second'"
  end
end
