require 'rack/contrib'
require 'rack/urlmap'
require 'delayed_job_web'
require './init'

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

DelayedJobWeb.disable :sessions

HonestyCluster.run_waitresses

run Rack::URLMap.new(
  '/' => Integrity.app,
  '/delayed_jobs' => DelayedJobWeb
)
