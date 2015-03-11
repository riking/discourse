class ExplorerQuery < ActiveRecord::Base
  belongs_to :creator, class_name: "User"
  has_many :params, class_name: "ExplorerQueryParameter"
  include Trashable

  def slug
    s = Slug.for(name)
    s = "query-#{id}" unless s.present?
    s
  end
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
