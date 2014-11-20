class ExplorerQuerySerializer < ApplicationSerializer
  attributes :name, :query, :public_view, :public_run, :can_run, :params

  def can_run
    object.public_run || scope.is_admin?
  end

  # has_many is being weird, so workaround
  def params
    object.params.map do |param|
      ExplorerQueryParameterSerializer.new(param, scope: scope, root: false)
    end
  end
end
