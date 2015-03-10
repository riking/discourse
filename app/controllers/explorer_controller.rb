
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

    equery = ExplorerQuery.find(params[:id])
    guardian.ensure_can_run_explorer_query!(equery)

    result = nil
    err = nil

    ActiveRecord::Base.transaction do
      ActiveRecord::Base.exec_sql "SET TRANSACTION READ ONLY"

      sql = <<SQL
WITH query AS (
  #{equery.query}
)
SELECT * FROM query;
SQL
      begin
        result = ActiveRecord::Base.exec_sql(sql, *params[:params])
      rescue PG::SyntaxError => ex
        err = ex
      end
    end

    binding.pry

    if err
      render json: {success: false, message: err.message, type: err.class}
    else
      cols = []
      res_ary = result.to_a
      if res_ary.present?
        cols = res_ary.first.keys
      end

      render json: {success: true, columns: cols, rows: result}
    end
  end

  #######

  def save
    params.require(:id)
    vals = params.permit(:name, :query, :public_view, :public_run)

    query = ExplorerQuery.find(params[:id])
    guardian.ensure_can_edit_explorer_query!(query)

    vals.keys.each do |k|
      query.send("#{k}=", vals[k])
    end

    params_ary = []
    if params[:params]
      params[:params].each do |k, v|
        params_ary[k.to_i] = v
      end
      params_ary.map! do |paramJson|
        paramJson[:param_type] = ExplorerQueryParameter.types[paramJson[:type]]
        paramJson.delete :type
        paramJson[:default_value] = "" unless paramJson[:default_value]

        ExplorerQueryParameter.new(paramJson)
      end
    end

    ExplorerQuery.transaction do
      if params[:params]
        query.params = params_ary
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

    eq = ExplorerQuery.new(name: params[:name], creator: current_user, query: "SELECT 1 value")
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
