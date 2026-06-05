class AddCurrentTeamShortCodeToLeaguePlayers < ActiveRecord::Migration[8.1]
  def change
    add_column :league_players, :current_team_short_code, :string

    League::Player.includes(:current_team).find_each do |player|
      player.update_column(:current_team_short_code, player.current_team&.short_code)
    end
  end
end
