class AddUniquenessConstraintOnTradeRequests < ActiveRecord::Migration[8.1]
  def change
    add_index :trade_requests, [:pool_team_id, :league_player_id],
      unique: true,
      where: "status = 0", # pending requests only
      name: "index_trade_requests_on_pending"
  end
end
