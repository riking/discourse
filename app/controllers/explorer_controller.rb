class ExplorerController < ApplicationController

  before_filter :check_enabled

  def index
    queries = ExplorerQuery.all
    unless guardian.is_admin?
      queries = queries.where(public_view: true)
    end

    render_serialized queries, BasicExplorerQuerySerializer
  end

  skip_before_filter :check_xhr, only: [:show]
  def show
    query = ExplorerQuery.with_deleted.find(params[:id])
    if params[:export]
      response.headers['Content-Disposition'] = "attachment; filename=#{query.slug}.json"
      response.sending_file = true
    else
      check_xhr
    end

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

    ####################
    # Process query parameters

    query_args = params[:params]
    query.params.each do |qparam|
      # Reset to default if restricted
      unless query_args.include?(qparam.name) && query_args[qparam.name] != "" &&
             guardian.can_edit_explorer_query_parameter?(qparam)

        query_args[qparam.name] = qparam.default_value
      end

      # Replace with computed value
      if query_args[qparam.name] =~ /^\$([a-z][a-z_]*)$/
        query_args[qparam.name] = ExplorerQueryParameter.calculated_value($1, self)
      end

      # Parse into native types
      case qparam.param_type
        when ExplorerQueryParameter.types[:int_list]
          arr = query_args[qparam.name]
          arr = arr.split(',') if arr.is_a? String
          arr = arr.map(&:to_i)
          query_args[qparam.name] = arr
        when ExplorerQueryParameter.types[:string_list]
          arr = query_args[qparam.name]
          arr = arr.split(',') if arr.is_a? String
          arr = arr.map(&:to_s)
          query_args[qparam.name] = arr
        else
          # no tranform
      end
    end

    ####################
    # Execute query

    begin
      ActiveRecord::Base.connection.transaction do
        ActiveRecord::Base.exec_sql "SET TRANSACTION READ ONLY" # extra safe
        if params[:explain] == "true"
          explain = ActiveRecord::Base.exec_sql "EXPLAIN #{query.query}", query_args
          explain = explain.map { |r| r["QUERY PLAN"] }.join "\n"
        end

        sql = <<SQL
  -- DataExplorer Query
  -- Query ID: #{query.id}
  -- Started by: #{current_user ? current_user.username : request.remote_ip}
  WITH query AS (

  #{query.query}

  ) SELECT * FROM query
SQL

        result = ActiveRecord::Base.exec_sql(sql, query_args)
      end
    rescue Exception => ex
      err = ex
    end

    ####################
    # Produce result

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
      cols = result.fields

      json = {
        success: true,
        columns: cols,
        rows: result,
        params: query_args,
        meta: {
          name: query.slug,
          date: Time.now,
          user: current_user ? current_user.username : '(not logged in)',
        }
      }
      json[:explain] = explain if params[:explain] == "true"
      if cols.any? { |c| c.match /\$/ }
        json[:relations] = DataExplorerSerialization.new.add_extra_data result
      end
      render json: json
    end
  end

  def update
    params.require(:id)
    vals = params.permit(:name, :query, :description, :public_view, :public_run)

    query = ExplorerQuery.includes(:params).find(params[:id])
    guardian.ensure_can_edit_explorer_query!(query)

    vals.keys.each do |k|
      query.send("#{k}=", vals[k])
    end

    # Prepare to update params
    old_params_ary = query.params
    new_params_ary = []
    full_update, partial_update = nil
    if params[:params]
      params[:params].each do |k, v|
        new_params_ary[k.to_i] = v unless k == ''
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
    elsif params[:params_empty] == 'true'
      full_update = true
    end

    ExplorerQuery.transaction do
      if full_update
        query.params = new_params_ary
      elsif partial_update
        old_params_ary.each(&:save)
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

    eq = ExplorerQuery.new(name: params[:name], creator: current_user, query: "SELECT 1 AS value\nLIMIT :limit")
    eq_param = ExplorerQueryParameter.new(name: "limit", param_type: ExplorerQueryParameter.types[:integer], default_value: 10)
    eq.params = [eq_param]
    eq.save

    render_serialized eq, ExplorerQuerySerializer
  end

  def destroy
    guardian.ensure_can_create_explorer_query!
    eq = ExplorerQuery.find(params[:id])
    eq.trash! current_user
    render json: success_json
  end

  def recover
    guardian.ensure_can_create_explorer_query!
    eq = ExplorerQuery.with_deleted.find(params[:explorer_id])
    eq.recover!
    render json: success_json
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

    return [true, false] if new.length != old.length

    old.each_with_index do |old_param, idx|
      new_param = new[idx]
      if new_param.name != old_param.name
        return [true, partial_updated]
      end

      ExplorerQueryParameter.in_place_attributes.each do |key|
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
