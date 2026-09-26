class ConvertAllTimestampToTimestamptz < ActiveRecord::Migration[8.1]
  TABLES_WITH_TIMESTAMPS = [
  :league_games, :league_players, :league_teams, :leagues, :pool_boxes,
  :pool_scorings, :pool_team_players, :pool_teams, :pools, :pwhl_goalie_stats,
  :pwhl_skater_stats, :sessions, :trade_requests, :trade_windows, :users
].freeze

  def up
    TABLES_WITH_TIMESTAMPS.each do |table|
      change_column table, :created_at, :timestamptz, null: false, using: "created_at AT TIME ZONE 'UTC'"
      change_column table, :updated_at, :timestamptz, null: false, using: "updated_at AT TIME ZONE 'UTC'"
    end

    change_column :pool_team_players, :added_at, :timestamptz, null: false, using: "added_at AT TIME ZONE 'UTC'"
    change_column :pool_team_players, :dropped_at, :timestamptz, using: "dropped_at AT TIME ZONE 'UTC'"
  end

  def down
    TABLES_WITH_TIMESTAMPS.each do |table|
      change_column table, :created_at, :datetime, null: false
      change_column table, :updated_at, :datetime, null: false
    end

    change_column :pool_team_players, :added_at, :datetime, null: false
    change_column :pool_team_players, :dropped_at, :datetime
  end
end
