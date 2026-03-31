class AddSeasonIdToPool < ActiveRecord::Migration[8.1]
  def change
    add_column :pools, :season_id, :string, null: false, default: "8"

    change_column_default :pools, :season_id, from: "8", to: nil
  end
end
