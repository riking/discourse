class BasicExplorerQuerySerializer < ApplicationSerializer
  attributes :id, :name, :description, :public_view, :can_run, :deleted
  has_one :creator, serializer: BasicUserSerializer, embed: :objects

  def can_run
    scope.can_run_explorer_query?(object)
  end

  def deleted
    object.deleted_at.present?
  end
end
