class ExplorerQueryParameterSerializer < ApplicationSerializer
  attributes :name, :param_type, :default_value

  def param_type
    ExplorerQueryParameter.types[object.param_type]
  end
end
