class AllowPoolBoxPositionIndexToDeferrable < ActiveRecord::Migration[8.1]
  def up
    remove_index :pool_boxes, [:pool_id, :position]
    execute <<-SQL
      ALTER TABLE pool_boxes
      ADD CONSTRAINT pool_boxes_pool_id_position_unique
      UNIQUE (pool_id, position)
      DEFERRABLE INITIALLY DEFERRED;
    SQL
  end

  def down
    execute <<-SQL
      ALTER TABLE pool_boxes
      DROP CONSTRAINT pool_boxes_pool_id_position_unique;
    SQL
    add_index :pool_boxes, [:pool_id, :position], unique: true
  end
end
