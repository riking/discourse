class ExplorerController < ApplicationController

  before_filter :check_enabled

  def index
    render nothing: true
  end

  def list
    # TODO real data
    render json: [
        {
            name: "2^n eligible posts",
            sql: "SELECT 2 foo, 3 AS bar, 4 AS baz",
            params: {},
            public_read: true,
            public_run: true,
            creator: {
                username: "PJH"
            }
        },
        {
            name: "Attendance",
            sql: "SELECT 2 foo, 3 AS bar, 4 AS baz FROM users WHERE user_id = :user_id",
            params: {
                user_id: "integer"
            },
            public_read: true,
            public_run: true,
            creator: {
                username: "PJH"
            }

        }
    ]
  end

  def show
    query = ExplorerQuery.find(params[:id])
    unless guardian.can_see?(query)
      raise Discourse::NotFound
    end

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