require 'rack/contrib'
require 'rack/urlmap'
require 'delayed_job_web'
require './init'

use Rack::PostBodyContentTypeParser

if (ENV['ADMIN_USERNAME'] || ENV['ADMIN_USER']) && ENV['ADMIN_PASSWORD']
  use Rack::Auth::Basic do |username, password|
    username == (ENV['ADMIN_USERNAME'] || ENV['ADMIN_USER']) && password == ENV['ADMIN_PASSWORD']
  end
end

run Rack::URLMap.new(
  '/'     => Integrity.app,
  '/jobs' => DelayedJobWeb
)

# run Delayed::Web::Engine, at: '/jobs'
# run Integrity.app
