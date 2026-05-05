class AddGameStartedToGoalieStat < ActiveRecord::Migration[8.1]
  def change
    add_column :pwhl_goalie_stats, :game_started, :boolean, default: false, null: false
    add_column :pwhl_skater_stats, :game_winning_goals, :int, default: 0, null: false
  end
end
