class ExplorerQuery < ActiveRecord::Base
  belongs_to :creator, class_name: "User"
  has_many :params, class_name: "ExplorerQueryParameter"
  include Trashable

  def slug
    s = Slug.for(name)
    s = "query-#{id}" unless s.present?
    s
  end

  def redis_key
    "explorer-result-#{id}"
  end

  def last_result
    last = $redis.get(redis_key)
    MultiJson.load(last) if last
  end

  def save_last_result(json)
    $redis.set(redis_key, MultiJson.dump(json))
  end

  def public_view=(new)
    super
    $redis.del(redis_key) unless new
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
