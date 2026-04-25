class AddPositionToPoolBox < ActiveRecord::Migration[8.1]
  def change
    add_column :pool_boxes, :position, :integer

    reversible do |dir|
      dir.up do
        Pool::Box.pluck(:pool_id).uniq.each do |pool_id|
          Pool::Box.where(pool_id: pool_id).order(:created_at).each_with_index do |r, i|
            r.update_column(:position, i)
          end
        end
      end
    end

    add_index :pool_boxes, [:pool_id, :position], unique: true
    change_column_null :pool_boxes, :position, false
  end
end
