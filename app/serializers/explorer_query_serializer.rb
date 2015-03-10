class ExplorerQuerySerializer < BasicExplorerQuerySerializer
  attributes :query, :public_run, :params, :can_edit

  def can_edit
    scope.can_edit?(object)
  end

  def params
    object.params
  end
end
