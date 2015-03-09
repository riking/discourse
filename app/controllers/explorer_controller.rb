require 'pg_query'

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
    params.require :sql
    begin
      sql = params[:sql]
      sql, paramNames = extract_params sql

      result = PgQuery.parse(sql)

      # lol hacks. this inserts more data into the json result
      result.instance_variable_set :@success, true
      result.instance_variable_set :@params, paramNames
      render json: result
    rescue PgQuery::ParseError => e
      render json: {success: false,
                    error_message: e.message,
                    error_loc: e.location}, status: 422
    end
  end

  def run
    params.require :id

    query = ExplorerQuery.find(params[:id])
    guardian.ensure_can_run_query!(query)
  end

  def save
    if params[:id].present?
      # edit
      query = ExplorerQuery.find(params[:id])
      guardian.ensure_can_edit_explorer_query!(query)
    else
      # create
      guardian.ensure_can_create_explorer_query!
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
