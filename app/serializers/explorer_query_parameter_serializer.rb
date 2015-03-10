class ExplorerQueryParameterSerializer < ApplicationSerializer
  attributes :name, :param_type, :default_value, :public_edit

  def param_type
    t = object.param_type
    q = ExplorerQueryParameter.types
    ExplorerQueryParameter.types[object.param_type]
  end
end
