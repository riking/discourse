class AddPublicallyEditableToExplorerQueryParameter < ActiveRecord::Migration
  def change
    add_column :explorer_query_parameters, :public_edit, :boolean, default: true
  end
end
