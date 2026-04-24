class AddReferenceSeasonToPool < ActiveRecord::Migration[8.1]
  def change
    add_column :pools, :reference_season_id, :string

    add_check_constraint :pools,
      "reference_season_id != season_id",
      name: "pools_reference_season_differs_from_season"
  end
end
