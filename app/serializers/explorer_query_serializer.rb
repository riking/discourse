class ExplorerQuerySerializer < BasicExplorerQuerySerializer
  attributes :query, :public_run, :can_edit, :params, :last_result
  has_many :params, serializer: ExplorerQueryParameterSerializer, embed: :objects

  def can_edit
    scope.can_edit?(object)
  end

  def include_last_result?
    object.public_view
  end
end
