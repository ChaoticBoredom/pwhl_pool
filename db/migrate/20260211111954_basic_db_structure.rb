class BasicDbStructure < ActiveRecord::Migration[8.1]
  def change
    create_table :leagues, id: :uuid do |t|
      t.string :name, null: false, index: { unique: true }
      t.string :short_name

      t.timestamps
    end

    create_table :league_teams, id: :uuid do |t|
      t.string :api_id, null: false
      t.string :name, null: false
      t.string :short_code

      t.references :league, type: :uuid, null: false, foreign_key: true

      t.index [:api_id, :league_id], unique: true

      t.timestamps
    end

    create_table :league_games, id: :uuid do |t|
      t.string :api_id, null: false
      t.string :season_id, null: false
      t.string :type, null: false
      t.date :date, null: false
      t.integer :status
      t.integer :home_team_score
      t.integer :away_team_score

      t.references :home_team, type: :uuid, null: false, foreign_key: { to_table: 'league_teams' }
      t.references :away_team, type: :uuid, null: false, foreign_key: { to_table: 'league_teams' }
      t.references :league, type: :uuid, null: false, foreign_key: true

      t.index [:api_id, :league_id], unique: true

      t.timestamps
    end

    create_table :league_players, id: :uuid do |t|
      t.string :api_id, null: false
      t.string :name, null: false
      t.string :type, null: false
      t.integer :position, null: false

      t.references :league, type: :uuid, null: false, foreign_key: true
      t.references :current_team, type: :uuid, foreign_key: { to_table: 'league_teams' }

      t.index [:api_id, :league_id], unique: true

      t.timestamps
    end

    create_table :pwhl_skater_stats, id: :uuid do |t|
      t.integer :goals, null: false
      t.integer :assists, null: false
      t.interval :penalty_minutes, null: false
      t.integer :shots, null: false
      t.integer :hits, null: false
      t.interval :time_on_ice, null: false
      t.integer :plus_minus, null: false
      t.integer :power_play_goals, null: false
      t.integer :short_handed_goals, null: false
      t.integer :shots_blocked, null: false
      t.integer :faceoffs_taken, null: false
      t.integer :faceoffs_won, null: false

      t.references :league_player, type: :uuid, null: false, foreign_key: true
      t.references :league_game, type: :uuid, null: false, foreign_key: true
      t.references :league_team, type: :uuid, null: false, foreign_key: true

      t.index [:league_player_id, :league_game_id], unique: true

      t.timestamps
    end

    create_table :pwhl_goalie_stats, id: :uuid do |t|
      t.integer :goals, null: false
      t.integer :assists, null: false
      t.integer :goals_against, null: false
      t.integer :shots_against, null: false
      t.integer :penalty_minutes, null: false
      t.boolean :win, null: false
      t.boolean :shutout, null: false
      t.integer :saves, null: false
      t.interval :time_on_ice, null: false

      t.references :league_player, type: :uuid, null: false, foreign_key: true
      t.references :league_game, type: :uuid, null: false, foreign_key: true
      t.references :league_team, type: :uuid, null: false, foreign_key: true

      t.index [:league_player_id, :league_game_id], unique: true

      t.timestamps
    end

    create_table :pools, id: :uuid do |t|
      t.string :name, null: false
      t.integer :pool_type, null: false

      t.references :league, type: :uuid, null: false, foreign_key: true
      t.references :admin, type: :uuid, null: false, foreign_key: { to_table: :users }

      t.timestamps
    end

    create_table :pool_scoring, id: :uuid do |t|
      t.float :skater_goals
      t.float :skater_assists
      t.float :skater_penalty_minutes
      t.float :skater_shots
      t.float :skater_hits
      t.float :goalie_goals
      t.float :goalie_assists
      t.float :goalie_penalty_minutes
      t.float :goalie_wins
      t.float :goalie_shutouts
      t.float :goalie_saves

      t.references :pool, type: :uuid, null: false, foreign_key: true

      t.timestamps
    end

    create_table :pool_teams, id: :uuid do |t|
      t.string :team_name

      t.references :user, type: :uuid, null: false, foreign_key: true
      t.references :pool, type: :uuid, null: false, foreign_key: true
    end

    create_table :pool_boxes, id: :uuid do |t|
      t.string :name, null: false
      t.uuid :players, array: true, null: false, default: []

      t.references :pool, type: :uuid, null: false, foreign_key: true

      t.timestamps
    end

    create_table :pool_team_players, id: :uuid do |t|
      t.references :pool_team, type: :uuid, null: false, foreign_key: true
      t.references :league_player, type: :uuid, null: false, foreign_key: true

      t.timestamps
    end
  end
end
