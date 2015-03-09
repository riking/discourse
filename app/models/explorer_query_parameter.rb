class ExplorerQueryParameter < ActiveRecord::Base
  belongs_to :explorer_query

  def self.types
    @types ||= Enum.new(:string, :integer, :int_list)
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
#
