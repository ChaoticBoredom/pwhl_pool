class ChangeGameStartToDatetime < ActiveRecord::Migration[8.1]
  def self.up
    change_column :league_games, :date, :timestamptz
    rename_column :league_games, :date, :start_time
  end

  def self.down
    rename_column :league_games, :start_time, :date
    change_column :league_games, :date, :date
  end
end
