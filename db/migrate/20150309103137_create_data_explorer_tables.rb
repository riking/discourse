class CreateDataExplorerTables < ActiveRecord::Migration
  def change
    create_table :explorer_queries do |t|
      t.string :name, null: false
      t.text :query, null: false
      t.integer :creator_id, null: false
      t.boolean :public_view, default: false, null: false
      t.boolean :public_run, default: false, null: false
      t.timestamps
    end

    create_table :explorer_query_parameters do |t|
      t.integer :explorer_query_id
      t.string :name, null: false
      t.integer :param_type, default: 0
      t.string :default_value
    end
  end
end
