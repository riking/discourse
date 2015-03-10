class ExplorerQueryParameter < ActiveRecord::Base
  belongs_to :explorer_query
  include CurrentUser

  def self.in_place_attributes
    @in_place_attributes ||= [:param_type, :default_value, :public_edit]
  end

  def self.types
    @types ||= Enum.new(:string, :integer, :int_list, :string_list, :json)
  end

  # NB: logic duplicated on server/client
  # client side: app/assets/javascripts/discourse/models/explorer_query_param.js.es6
  def self.calculated_value(name, controller)
    case name
      when "current_user_id"
        controller.current_user.try(:id)
      when "visible_categories"
        Site.new(controller.guardian).categories.map(&:id)
      else
        "$#{name}"
    end
  end
end

# == Schema Information
#
# Table name: explorer_query_parameters
#
#  id                :integer          not null, primary key
#  explorer_query_id :integer          not null
#  name              :string(255)      not null
#  param_type        :integer          default(0)
#  default_value     :string(255)
#  public_edit       :boolean          default(true)
#
