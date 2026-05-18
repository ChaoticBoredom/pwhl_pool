class AddTradePolicyAndTradeRequests < ActiveRecord::Migration[8.1]
  def up
    add_column :pools, :trade_policy, :integer, null: false, default: 0

    execute <<~SQL
      UPDATE pools SET trade_policy = CASE
        WHEN trades_allowed = true THEN 300
        ELSE 0
      END
    SQL

    remove_column :pools, :trades_allowed
    remove_column :pools, :trades_require_approval

    create_table :trade_requests, id: :uuid do |t|
      t.references :pool_team, null: false, foreign_key: { to_table: :pool_teams }, type: :uuid
      t.references :requested_by, null: false, foreign_key: { to_table: :users }, type: :uuid
      t.references :league_player, null: false, foreign_key: { to_table: :league_players }, type: :uuid
      t.references :pool_box, null: true, foreign_key: { to_table: :pool_boxes }, type: :uuid

      t.uuid :request_group_id, null: true
      t.integer :action, null: false
      t.integer :status, null: false, default: 0
      t.timestamptz :requested_at, null: false
      t.timestamptz :decided_at, null: true
      t.timestamptz :backdated_to, null: true
      t.text :rejected_reason, null: true

      t.timestamps
    end

    add_index :trade_requests, :request_group_id
    add_index :trade_requests, :status
    add_index :trade_requests, [:pool_team_id, :status]
    add_index :trade_requests, [:league_player_id, :status]
  end

  def down
    drop_table :trade_requests

    add_column :pools, :trades_allowed, :boolean, null: false, default: false
    add_column :pools, :trades_require_approval, :boolean, null: false, default: false

    execute <<~SQL
      UPDATE pools SET trades_allowed = CASE
        WHEN trade_policy >= 100 THEN true
        ELSE false
      END
    SQL

    remove_column :pools, :trade_policy
  end
end
