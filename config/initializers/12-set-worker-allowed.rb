class Discourse::ServiceWorkerAllowed
  def initialize(app, options = nil)
    @app = app
  end

  def call(env)
    request = Rack::Request.new(env)
    response = @app.call(env)
    if request.path == '/assets/worker.js'
      response[1]['Service-Worker-Allowed'] = Discourse.base_uri '/'
    end
    response
  end
end

Rails.configuration.middleware.use Discourse::ServiceWorkerAllowed
