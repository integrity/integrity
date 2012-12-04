require File.expand_path("../init", __FILE__)
if (ENV['ADMIN_USERNAME'] || ENV['ADMIN_PASS']) && ENV['ADMIN_PASSWORD']
  use Rack::Auth::Basic do |username, password|
    username == (ENV['ADMIN_USERNAME'] || ENV['ADMIN_PASS']) && password == ENV['ADMIN_PASSWORD']
  end
end
run Integrity.app
