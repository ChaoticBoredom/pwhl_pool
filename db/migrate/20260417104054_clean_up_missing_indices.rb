class CleanUpMissingIndices < ActiveRecord::Migration[8.1]
  def change
    change_column_null :pool_teams, :team_name, false
    add_index :pool_teams, [:pool_id, :user_id], unique: true

    add_index :pool_boxes, :league_player_ids, using: :gin

    add_index :pool_team_players, [:pool_team_id, :league_player_id],
      unique: true,
      where: "dropped_at IS NULL",
      name: "index_unique_active_player_per_team"

    add_index :pwhl_skater_stats, [:league_player_id, :league_game_id], name: "index_skater_stats_on_player_and_game"
    add_index :pwhl_goalie_stats, [:league_player_id, :league_game_id], name: "index_goalie_stats_on_player_and_game"
  end
end
