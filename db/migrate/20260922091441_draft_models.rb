class DraftModels < ActiveRecord::Migration[8.1]
  def change
    create_table :drafts, id: :uuid do |t|
      t.references :pool, type: :uuid, null: false, foreign_key: true, index: { unique: true }
      t.integer :state, null: false, default: 0
      t.integer :pick_order_strategy, null: false, default: 0
      t.timestamp :start_at, null: false
      t.integer :current_pick_number, null: false, default: 0
      t.uuid :team_order, array: true, null: false, default: []

      t.timestamps
    end

    create_table :draft_picks, id: :uuid do |t|
      t.references :draft, type: :uuid, null: false, foreign_key: true
      t.references :pool_team, type: :uuid, null: false, foreign_key: true

      t.integer :pick_number, null: false
      t.integer :round, null: false

      t.references :league_player, type: :uuid, null: true, foreign_key: true
      t.references :tentative_league_player, type: :uuid, foreign_key: { to_table: :league_players }

      t.timestamp :made_at, null: true
      t.boolean :auto_picked, null: false, default: false

      t.timestamps
    end

    add_index :draft_picks, [:draft_id, :pick_number], unique: true

    create_table :draft_roster_slots, id: :uuid do |t|
      t.references :pool, type: :uuid, null: false, foreign_key: true
      t.integer :category, null: false
      t.integer :count, null: false

      t.timestamps
    end

    add_index :draft_roster_slots, [:pool_id, :category], unique: true

    add_column :pool_team_players, :position_category, :integer
  end
end
