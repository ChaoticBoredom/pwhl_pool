class DenormalizeSomeTeamPlayerData < ActiveRecord::Migration[8.1]
  def change
    add_column :pool_team_players, :pool_id, :uuid
    add_column :pool_team_players, :position, :int

    up_only do
      execute <<-SQL
        UPDATE pool_team_players
        SET
          pool_id = pool_teams.pool_id,
          position = league_players.position
        FROM pool_teams, league_players
        WHERE pool_team_players.pool_team_id = pool_teams.id
          AND pool_team_players.league_player_id = league_players.id
      SQL

      change_column_null :pool_team_players, :pool_id, false
      change_column_null :pool_team_players, :position, false
    end
  end
end
