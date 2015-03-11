class AddTrashableToExplorerQuery < ActiveRecord::Migration
  def change
    add_column :explorer_queries, :deleted_at, :timestamp
    add_column :explorer_queries, :deleted_by_id, :integer
  end
end
