class AddTradeWindows < ActiveRecord::Migration[8.1]
  def change
    create_table :pool_trade_windows, id: :uuid do |t|
      t.belongs_to :pool, foreign_key: true, type: :uuid
      t.tstzrange :open_window, index: { using: :gist }, null: false

      t.timestamps
    end

    add_column :pools, :trades_allowed, :boolean, default: false
    add_column :pools, :trades_require_approval, :boolean, default: false
  end
end
