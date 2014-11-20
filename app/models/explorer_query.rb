class ExplorerQuery < ActiveRecord::Base
  belongs_to :creator, class_name: "User"
  has_many :explorer_query_parameters

end

# == Schema Information
#
# Table name: explorer_queries
#
#  id          :integer          not null, primary key
#  name        :string(255)      not null
#  query       :text             not null
#  creator_id  :integer          not null
#  public_view :boolean          default(FALSE), not null
#  public_run  :boolean          default(FALSE), not null
#  created_at  :datetime
#  updated_at  :datetime
#
