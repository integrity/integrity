require File.expand_path("../init", __FILE__)

if (ENV['ADMIN_USERNAME'] || ENV['ADMIN_USER']) && ENV['ADMIN_PASSWORD']
  use Rack::Auth::Basic do |username, password|
    username == (ENV['ADMIN_USERNAME'] || ENV['ADMIN_USER']) && password == ENV['ADMIN_PASSWORD']
  end
end

if Integrity.config.builder.respond_to? :web_ui
  path, app = Integrity.config.builder.web_ui

  map "/#{path}" do
    run app
  end
end

map '/' do
  run Integrity.app
end
