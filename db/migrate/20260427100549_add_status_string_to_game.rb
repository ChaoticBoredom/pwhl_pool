class AddStatusStringToGame < ActiveRecord::Migration[8.1]
  def change
    add_column :league_games, :current_description, :string
  end
end
