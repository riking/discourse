
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

    render_serialized queries, ExplorerQuerySerializer
  end

  def show
    query = ExplorerQuery.find(params[:id])
    guardian.ensure_can_see!(query)
    render_serialized query, ExplorerQuerySerializer
  end

  def parse

    render json: {success: true}
  end

  def run
    params.require :id

    equery = ExplorerQuery.find(params[:id])
    guardian.ensure_can_run_query!(equery)

    ActiveRecord::Base.transaction do
      ActiveRecord::Base.exec_sql "SET TRANSACTION READ ONLY"

      result = ActiveRecord::Base.exec_sql <<SQL
WITH query AS (
  #{equery.query}
)
SELECT * FROM query;
SQL

      binding.pry
    end
  end

  def save
    # TODO saving params is weird
    vals = params.permit(:name, :query, :params, :public_view, :public_run)

    query = ExplorerQuery.find(params[:id])
    guardian.ensure_can_edit_explorer_query!(query)

    vals.keys.each do |k|
      query.send("#{k}=", vals[k])
    end

    query.save
    if query.errors.present?
      render_json_error query
    else
      render json: success_json
    end
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
