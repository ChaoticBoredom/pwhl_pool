class AddBoxReferenceToTeamPlayer < ActiveRecord::Migration[8.1]
    def up
    add_column :pool_team_players, :pool_box_id, :uuid

    Pool::TeamPlayer.find_each do |tp|
      box = Pool::Box.where(pool_id: tp.pool_id)
                     .find { |b| b.league_player_ids.include?(tp.league_player_id) }
      tp.update_columns(pool_box_id: box&.id)
    end

    unmatched = Pool::TeamPlayer.where(pool_box_id: nil).count
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
