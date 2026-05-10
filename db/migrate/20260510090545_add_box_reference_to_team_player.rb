class AddBoxReferenceToTeamPlayer < ActiveRecord::Migration[8.1]
    def up
    add_column :pool_team_players, :pool_box_id, :uuid

    execute <<-SQL
      UPDATE pool_team_players ptp
      SET pool_box_id = pb.id
      FROM pool_boxes pb
      WHERE pb.pool_id = ptp.pool_id
      AND ptp.league_player_id = ANY(pb.league_player_ids)
    SQL

    unmatched = execute("SELECT COUNT(*) FROM pool_team_players WHERE pool_box_id IS NULL").first["count"].to_i
    raise "Backfill incomplete: #{unmatched} team players without a box" if unmatched > 0

    change_column_null :pool_team_players, :pool_box_id, false
    add_index :pool_team_players, :pool_box_id
    add_foreign_key :pool_team_players, :pool_boxes, column: :pool_box_id
  end

  def down
    remove_foreign_key :pool_team_players, column: :pool_box_id
    remove_column :pool_team_players, :pool_box_id
  end
end
