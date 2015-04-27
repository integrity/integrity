require 'rack/contrib'
require 'rack/urlmap'
require 'delayed_job_web'
require './init'

class InspectMiddleware
  require "yaml"

  def initialize(app)
    @app = app
  end

  def call(env)
    puts
    puts "-"*80
    puts "Request Pipeline"
    print_middleware_class = lambda do |klass|
      if middleware = klass.instance_variable_get(:@app)
        print "#{middleware.class} -> "
        print_middleware_class.call(middleware)
      else
        puts
        puts "#{klass.class} is a rack endpoint"
        puts
        puts "Class:"
        puts klass.inspect
        puts "-"*80
        puts
      end
    end

    print_middleware_class.call(@app)

    @app.call(env)
  end
end

user InspectMiddleware
use Rack::PostBodyContentTypeParser
use Rack::Session::Cookie, key: 'rack.session', path: '/', secret: 'secret', expire_after: 1800 # 30mins
use Rack::Flash

client_id     = ENV['GITHUB_CLIENT_ID']
client_secret = ENV['GITHUB_CLIENT_SECRET']
auth_scope    = 'user:email,repo:status,read:repo_hook,read:org'
use OmniAuth::Builder do
  provider :github, client_id, client_secret, scope: auth_scope
end

username = ENV['ADMIN_USERNAME'] || ENV['ADMIN_USER']
password = ENV['ADMIN_PASSWORD']
if username && password
  use Rack::Auth::Basic do |username, password|
    username == (ENV['ADMIN_USERNAME'] || ENV['ADMIN_USER']) && password == ENV['ADMIN_PASSWORD']
  end
end

run Rack::URLMap.new(
  '/' => Integrity.app,
  '/delayed_jobs' => DelayedJobWeb
)
