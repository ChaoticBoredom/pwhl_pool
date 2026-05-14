class DenormalizeStartTimeAndSeasonIdToStats < ActiveRecord::Migration[8.1]
  def change
    add_column :pwhl_skater_stats, :start_time, :timestamptz
    add_column :pwhl_skater_stats, :season_id, :string
    add_column :pwhl_goalie_stats, :start_time, :timestamptz
    add_column :pwhl_goalie_stats, :season_id, :string

    reversible do |dir|
      dir.up do
        execute <<~SQL
          UPDATE pwhl_skater_stats s
          SET
            start_time = lg.start_time,
            season_id = lg.season_id
          FROM league_games lg
          WHERE s.league_game_id = lg.id
        SQL

        execute <<~SQL
          UPDATE pwhl_goalie_stats g
          SET
            start_time = lg.start_time,
            season_id = lg.season_id
          FROM league_games lg
          WHERE g.league_game_id = lg.id
        SQL
      end
    end

    add_index :pwhl_skater_stats, [:season_id, :start_time]
    add_index :pwhl_goalie_stats, [:season_id, :start_time]

    change_column_null :pwhl_skater_stats, :start_time, false
    change_column_null :pwhl_skater_stats, :season_id, false
    change_column_null :pwhl_goalie_stats, :start_time, false
    change_column_null :pwhl_goalie_stats, :season_id, false
  end
end
