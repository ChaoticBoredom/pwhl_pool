class RenameRosterTypeToStatType < ActiveRecord::Migration[8.1]
  def change
    rename_column :league_players, :roster_type, :stat_type
    rename_column :pool_scorings, :roster_type, :stat_type
    rename_column :pool_team_players, :roster_type, :stat_type
  end
end
