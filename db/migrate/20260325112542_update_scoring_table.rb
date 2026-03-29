class UpdateScoringTable < ActiveRecord::Migration[8.1]
  def change
    drop_table :pool_scorings do |t|
      t.string :field_name, null: false
      t.float :value, null: false

      t.references :pool, type: :uuid, null: false, foreign_key: true

      t.timestamps
    end

    create_table :pool_scorings, id: :uuid do |t|
      t.string :field_name, null: false
      t.integer :position, null: false
      t.float :value, null: false

      t.references :pool, type: :uuid, null: false, foreign_key: true

      t.index [:pool_id, :field_name, :position], unique: true

      t.timestamps
    end
  end
end
