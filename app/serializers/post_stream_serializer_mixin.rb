require_dependency 'gap_serializer'
require_dependency 'post_serializer'

module PostStreamSerializerMixin

  def self.included(klass)
    klass.attributes :post_stream
  end

  def post_stream
    result = { posts: posts, stream: object.filtered_post_ids }
    result[:gaps] = GapSerializer.new(object.gaps, root: false) if object.gaps.present?
    result
  end

  def posts
    return @posts if @posts.present?
    @posts = []
    if object.posts
      object.posts.each_with_index do |p, idx|
        p.topic = object.topic
        ps = PostSerializer.new(p, scope: scope, root: false)
        ps.topic_slug = object.topic.slug
        ps.topic_view = object

        @posts << ps.as_json
      end
    end
    @posts
  end

end
