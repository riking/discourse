class ExplorerQuerySerializer < ApplicationSerializer
  attributes :id, :name, :query, :public_view, :public_run, :params
  attributes :can_run, :can_edit

  def can_run
    scope.can_run_explorer_query?(object)
  end

  def can_edit
    scope.can_edit?(object)
  end

  # has_many is being weird, so workaround
  def params
    object.params.map do |param|
      ExplorerQueryParameterSerializer.new(param, scope: scope, root: false)
    end
  end
end
