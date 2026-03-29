class AddPickedUpAndDroppedDatesToPoolPlayers < ActiveRecord::Migration[8.1]
  def change
    change_table :pool_team_players do |t|
      t.timestamp :added_at, null: false
      t.timestamp :dropped_at
    end
  end
end
