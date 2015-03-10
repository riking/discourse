class ExplorerQuerySerializer < BasicExplorerQuerySerializer
  attributes :query, :public_run, :can_edit, :params
  has_many :params, serializer: ExplorerQueryParameterSerializer, embed: :objects

  def can_edit
    scope.can_edit?(object)
  end
end
