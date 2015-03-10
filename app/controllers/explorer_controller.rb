
class ExplorerController < ApplicationController

  before_filter :check_enabled

  def index
    render nothing: true
  end

  def list
    # TODO real data
    queries = ExplorerQuery.all
    unless guardian.is_admin?
      queries = queries.where(public_view: true)
    end

    render_serialized queries, BasicExplorerQuerySerializer
  end

  def show
    query = ExplorerQuery.find(params[:id])
    guardian.ensure_can_see!(query)
    render_serialized query, ExplorerQuerySerializer
  end

  def run
    params.require :id

    query = ExplorerQuery.find(params[:id])
    guardian.ensure_can_run_explorer_query!(query)

    result = nil
    err = nil
    explain = nil

    begin
      ActiveRecord::Base.connection.transaction do
        ActiveRecord::Base.exec_sql "SET TRANSACTION READ ONLY"
        if params[:explain] == "true"
          explain = ActiveRecord::Base.exec_sql "EXPLAIN #{query.query}", params[:params]
        end

        sql = <<SQL
-- DataExplorer Query
-- Query ID: #{query.id}
-- Started by: #{current_user.username}
WITH query AS (

#{query.query}

) SELECT * FROM query
SQL

        result = ActiveRecord::Base.exec_sql(sql, params[:params])
      end
    rescue Exception => ex
      err = ex
    end

    if err
      # Pretty printing logic
      err_class = err.class
      err_msg = err.message
      if err.is_a? ActiveRecord::StatementInvalid
        err_class = err.original_exception.class
        err_msg.gsub!("#{err_class.to_s}:", '')
      end
      render json: {success: false, message: err_msg, class: err_class.to_s}
    else
      cols = []
      res_ary = result.to_a
      if res_ary.present?
        cols = res_ary.first.keys
      end

      result = {success: true, columns: cols, rows: result, params: params[:params]}
      result[:explain] = explain if params[:explain]
      render json: result
    end
  end

  #######

  def save
    params.require(:id)
    vals = params.permit(:name, :query, :description, :public_view, :public_run)

    query = ExplorerQuery.includes(:params).find(params[:id])
    guardian.ensure_can_edit_explorer_query!(query)

    vals.keys.each do |k|
      query.send("#{k}=", vals[k])
    end

    # TODO perf, assigning a brand-new array is wasteful
    old_params_ary = query.params
    new_params_ary = []
    full_update, partial_update = nil
    if params[:params]
      params[:params].each do |k, v|
        new_params_ary[k.to_i] = v
      end
      new_params_ary.map! do |paramJson|
        paramJson[:param_type] = ExplorerQueryParameter.types[paramJson[:type]]
        paramJson.delete :type
        paramJson[:default_value] = "" unless paramJson[:default_value]

        ExplorerQueryParameter.new(paramJson)
      end
      new_params_ary.sort_by! { |p| p.name }

      # Check for equality
      full_update, partial_update = update_param_array(new_params_ary, old_params_ary)
    end

    ExplorerQuery.transaction do
      if params[:params]
        if full_update
          query.params = new_params_ary
        elsif partial_update
          old_params_ary.each(&:save)
        end
      end
      query.save
    end

    if query.errors.present?
      render_json_error query
    else
      render_serialized query, ExplorerQuerySerializer
    end
  end

  def create
    params.require(:name)
    guardian.ensure_can_create_explorer_query!

    eq = ExplorerQuery.new(name: params[:name], creator: current_user, query: "SELECT 1 value\nLIMIT :limit")
    eq.save

    render_serialized eq, ExplorerQuerySerializer
  end

  private

  def extract_params(sql)
    names = []
    new_sql = sql.gsub(/:([a-z_]+)/) do |match|
      names << $1
      "$#{names.length - 1}"
    end
    [new_sql, names]
  end

  def update_param_array(new, old)
    partial_updated = false
    @MODIFY_IN_PLACE_ATTRS ||= [:param_type, :default_value]

    old.each_with_index do |old_param, idx|
      new_param = new[idx]
      if new_param.name != old_param.name
        return [true, partial_updated]
      end

      @MODIFY_IN_PLACE_ATTRS.each do |key|
        if new_param[key] != old_param[key]
          old_param[key] = new_param[key]
          partial_updated = true
        end
      end
    end
    return [false, partial_updated]
  end

  def check_enabled
    return if Rails.env.development?

    unless SiteSetting.enable_data_explorer
      raise Discourse::NotFound
    end
    unless guardian.is_admin? || SiteSetting.public_data_explorer
      raise Discourse::InvalidAccess
    end
  end
end
