class AddPoolStateColumn < ActiveRecord::Migration[8.1]
  def up
    add_column :pools, :state, :integer, null: false, default: 0

    execute <<~SQL
      UPDATE pools SET state = 200 WHERE season_id = '8';
      UPDATE pools SET state = 100 WHERE season_id = '9';
    SQL
  end

  def down
    remove_column :pools, :state
  end
end
