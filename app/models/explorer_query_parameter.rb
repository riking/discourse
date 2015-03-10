class ExplorerQueryParameter < ActiveRecord::Base
  belongs_to :explorer_query
  include CurrentUser

  def self.in_place_attributes
    @in_place_attributes ||= [:param_type, :default_value, :public_edit]
  end

  def self.types
    @types ||= Enum.new(:string, :integer, :int_list, :current_user_id, :visible_categories)
  end

  def self.calculated_default_types
    [types[:current_user_id], types[:visible_categories]]
  end

  def calculated_default?
    ExplorerQueryParameter.calculated_default_types.include? param_type
  end

  def calculated_default(controller)
    case param_type
      when ExplorerQueryParameter.types[:current_user_id]
        controller.current_user.try(:id)
      when ExplorerQueryParameter.types[:visible_categories]
        Site.new(controller.guardian).categories.map(&:id)
      else
        default_value
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
