class ExplorerQuery < ActiveRecord::Base
  belongs_to :creator, class_name: "User"
  has_many :parameters, :explorer_query_parameters

end

# == Schema Information
#
# Table name: explorer_queries
#
#  id          :integer          not null, primary key
#  name        :string(255)
#  query       :text
#  creator_id  :integer
#  public_view :boolean
#  public_run  :boolean
#  created_at  :datetime
#  updated_at  :datetime
#
