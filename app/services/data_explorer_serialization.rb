class DataExplorerSerialization

  class SmallBadgeSerializer < ApplicationSerializer
    attributes :id, :name, :badge_type, :description, :icon
    def badge_type
      object.badge_type.name
    end
  end

  class SmallPostWExcerptSerializer < ApplicationSerializer
    attributes :id, :topic_id, :post_number, :excerpt
    attributes :username, :uploaded_avatar_id
    def excerpt
      Post.excerpt(object.cooked, 70)
    end
    def username; object.user.username; end
    def uploaded_avatar_id; object.user.uploaded_avatar_id; end
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
      {class: Badge, fields: [:id, :name, :badge_type_id, :description, :icon], include: [:badge_type], serializer: SmallBadgeSerializer},
      {class: Post, fields: [:id, :topic_id, :post_number, :cooked, :user_id], include: [:user], serializer: SmallPostWExcerptSerializer},
      {class: Topic, fields: [:id, :title, :slug, :posts_count], serializer: BasicTopicSerializer}
    ]
  end

  #
  def self.client_only_types
    @client_only_types ||= ['reltime', 'category']
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
        out[m[1]] = [] # ACK the client
      end
      return
    end
    fnumber = result.fnumber(col)
    return unless result.ftype(fnumber) == DataExplorerSerialization.int_type_id
    # Okay, insanity checks out of the way

    all_ids = result.column_values(fnumber).map { |s| s.try(:to_i) }.sort do |a, b|
      if a.nil?
        -1
      elsif b.nil?
        1
      else
        a <=> b
      end
    end.uniq
    all_objs = support_info[:class].select(support_info[:fields]).where(id: all_ids).includes(support_info[:include])
    out[m[1]] = ActiveModel::ArraySerializer.new(all_objs, each_serializer: support_info[:serializer])
  end
end
