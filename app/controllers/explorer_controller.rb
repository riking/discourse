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
    unless guardian.can_see?(query)
      raise Discourse::NotFound
    end

    render_serialized query
  end

  def run

  end

  def save

  end

  def check_enabled
    unless SiteSetting.enable_data_explorer
      raise Discourse::NotFound
    end
    unless guardian.is_admin? || SiteSetting.public_data_explorer
      raise Discourse::InvalidAccess
    end
  end
end
