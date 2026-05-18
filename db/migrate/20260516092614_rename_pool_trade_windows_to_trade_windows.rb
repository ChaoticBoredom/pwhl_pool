class RenamePoolTradeWindowsToTradeWindows < ActiveRecord::Migration[8.1]
  def change
    rename_table :pool_trade_windows, :trade_windows
  end
end
