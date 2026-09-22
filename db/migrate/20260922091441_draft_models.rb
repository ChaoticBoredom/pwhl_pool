class DraftModels < ActiveRecord::Migration[8.1]
  def change
    create_table :drafts, id: :uuid do |t|
      t.references :pool, :uuid, null: false, foreign_key: true
      t.integer :state
      t.integer :pick_order_strategy, null: false
      t.integer :current_pick_number
      t.uuid :team_order, array: true, null: false, default: []

      t.timestamps
    end

    create_table :draft_picks, id: :uuid do |t|
      t.references :draft, :uuid, null: false, foreign_key: true
      t.references :pool_team, :uuid, null: false, foreign_key: true
      t.integer :pick_number, null: false
      t.integer :round, null: false
      t.references :league_player, :uuid, null: true, foreign_key: true
      t.timestamp :made_at, null: true
      t.boolean :auto_picked, null: false, default: false
      t.references :tentative_league_player_id, :uuid, foreign_key: { to_table: 'league_players' }

      t.timestamps
    end

    add_index :draft_picks, [:pick_number, :draft_id], unique: true

    create_table :draft_roster_slots, id: :uuid do |t|
      t.references :pool, :uuid, null: false, foreign_key: true
      t.integer :category, null: false
      t.integer :count, null: false

      t.timestamps
    end

    add_index :draft_roster_slots, [:pool_id, :category], unique: true

    add_column :pool_team_players, :position_category, :integer
  end
end
