class AdjustPositionAndAddFlagsToLeaguePlayers < ActiveRecord::Migration[8.1]
  def change
    # Preparing to rename 'position' to 'roster_type'
    rename_column :league_players, :position, :roster_type
    rename_column :pool_scorings, :position, :roster_type
    rename_column :pool_team_players, :position, :roster_type

    add_column :league_players, :position, :string

    add_column :league_players, :rookie, :boolean, default: false, null: false
    add_column :league_players, :active, :boolean, default: true, null: false
  end
end
