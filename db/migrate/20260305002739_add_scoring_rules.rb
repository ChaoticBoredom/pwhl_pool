class AddScoringRules < ActiveRecord::Migration[8.1]
  def change
    drop_table :pool_scoring do |t|
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

    create_table :pool_scorings, id: :uuid do |t|
      t.string :field_name, null: false
      t.float :value, null: false

      t.references :pool, type: :uuid, null: false, foreign_key: true

      t.timestamps
    end
  end
end
