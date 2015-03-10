class BasicExplorerQuerySerializer < ApplicationSerializer
  attributes :id, :name, :description, :public_view, :can_run
  has_one :creator, serializer: BasicUserSerializer, embed: :objects

  def description
    "TODO add to table"
  end

  def can_run
    scope.can_run_explorer_query?(object)
  end
end
