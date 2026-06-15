class UpdateUniqunessForPoolBoxes < ActiveRecord::Migration[8.1]
  def change
    remove_unique_constraint :pool_boxes, name: "pool_boxes_pool_id_position_unique"
    add_unique_constraint :pool_boxes, [:pool_id, :active, :position],
      deferrable: :deferred,
      name: "pool_boxes_pool_id_active_position_unique"
  end
end
