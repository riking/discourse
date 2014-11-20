class CreateDataExplorerTables < ActiveRecord::Migration
  def change
    create_table :explorer_queries do |t|
      t.string :name
      t.text :query
      t.integer :creator_id
      t.boolean :public_view
      t.boolean :public_run
      t.timestamps
    end

    create_table :explorer_query_parameters do |t|
      t.integer :explorer_query_id
      t.string :param_name
      t.integer :type
    end
  end
end
