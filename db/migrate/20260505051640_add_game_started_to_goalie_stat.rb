class AddGameStartedToGoalieStat < ActiveRecord::Migration[8.1]
  def change
    add_column :pwhl_goalie_stats, :game_started, :boolean, default: false, null: false
  end
end
