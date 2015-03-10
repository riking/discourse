class DataExplorerSerialization

  class SmallBadgeSerializer < ApplicationSerializer
    attributes :id, :name, :badge_type, :description, :icon
    def badge_type
      BadgeType.find(object.badge_type_id).name
    end
  end

  class SmallPostWExcerptSerializer < ApplicationSerializer
    attributes :id, :topic_id, :post_number, :excerpt
    def excerpt
      Post.excerpt(object.cooked, 70)
    end
  end

  # This dance is to reduce the server <-> db bandwidth, as we might need to
  # move a lot of data to load all of the posts/topics referenced in the
  # query's results.
  # Optimizing for wire size, not server time.
  #
  # An array of hashes in the following format:
  #   class: ActiveModel class
  #   fields: Array of DB fields needed by serializer
  #   serializer: Serializer to use
  def self.supported_types
    @supported_types ||= [
      {class: User, fields: [:id, :username, :uploaded_avatar_id], serializer: BasicUserSerializer},
      {class: Badge, fields: [:id, :name, :badge_type_id, :description, :icon], serializer: SmallBadgeSerializer},
      {class: Post, fields: [:id, :topic_id, :post_number, :cooked, :user_id], serializer: SmallPostWExcerptSerializer},
      {class: Topic, fields: [:id, :title, :fancy_title, :slug, :posts_count], serializer: BasicTopicSerializer}
    ]
  end

  #
  def self.client_only_types
    @client_only_types ||= ['reltime']
  end

  def self.int_type_id
    @int_type_id ||= begin
      res = ActiveRecord::Base.exec_sql("SELECT 1")
      res.ftype(0)
    end
  end

  def add_extra_data(result)
    out = {}
    cols = result.fields.select { |c| c.match /\$/ }
    cols.each do |col|
      begin
        add_data_for(col, result, out)
      rescue => e
        Rails.logger.warn e
      end
    end
    out
  end

  def add_data_for(col, result, out)
    m = col.match /^(\w+)\$(\w*)$/
    return unless m && m[1]

    support_info = DataExplorerSerialization.supported_types.select { |info| info[:class].to_s.downcase == m[1] }.first
    unless support_info
      if DataExplorerSerialization.client_only_types.include? m[1]
        out[m[1]] = []
      end
      return
    end
    fnumber = result.fnumber(col)
    return unless result.ftype(fnumber) == DataExplorerSerialization.int_type_id
    # Okay, insanity checks out of the way

    all_ids = result.column_values(fnumber).uniq
    all_objs = support_info[:class].select(support_info[:fields]).where(id: all_ids)
    out[m[1]] = ActiveModel::ArraySerializer.new(all_objs, each_serializer: support_info[:serializer])
  end
end
