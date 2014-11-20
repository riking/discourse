class ExplorerQueryParameter < ActiveRecord::Base
  belongs_to :explorer_query
end

# == Schema Information
#
# Table name: explorer_query_parameters
#
#  id                :integer          not null, primary key
#  explorer_query_id :integer          not null
#  param_name        :string(255)      not null
#  type              :integer          not null
#
