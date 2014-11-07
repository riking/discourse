require_dependency 'site_serializer'

class SiteController < ApplicationController

  def index
    render_json_dump(Site.json_for(guardian))
  end

  def settings
    render_json_dump(SiteSetting.client_settings_json)
  end

  def custom_html
    render_json_dump(custom_html_json)
  end

  def banner
    render_json_dump(banner_json)
  end
end
