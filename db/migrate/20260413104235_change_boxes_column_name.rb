class ChangeBoxesColumnName < ActiveRecord::Migration[8.1]
  def change
    rename_column :pool_boxes, :players, :league_player_ids
  end
end
