class RemoveNullOnPoolTeamBoxes < ActiveRecord::Migration[8.1]
  def change
    change_column_null :pool_team_players, :pool_box_id, true
  end
end
