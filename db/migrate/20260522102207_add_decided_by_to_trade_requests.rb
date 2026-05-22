class AddDecidedByToTradeRequests < ActiveRecord::Migration[8.1]
  def change
    add_reference :trade_requests,
      :decided_by,
      foreign_key: { to_table: :users },
      type: :uuid,
      null: true
  end
end
