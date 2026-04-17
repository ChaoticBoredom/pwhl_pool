class AddTimestampsToPoolTeams < ActiveRecord::Migration[8.1]
  def change
    add_timestamps :pool_teams, null: false, default: -> { 'CURRENT_TIMESTAMP' }
  end
end
