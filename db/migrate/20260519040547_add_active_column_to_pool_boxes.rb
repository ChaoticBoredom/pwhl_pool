class AddActiveColumnToPoolBoxes < ActiveRecord::Migration[8.1]
  def change
    add_column :pool_boxes, :active, :boolean, default: true, null: false
  end
end
