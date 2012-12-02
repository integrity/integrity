require File.expand_path("../init", __FILE__)
if ENV['ADMIN_USERNAME'] && ENV['ADMIN_PASSWORD']
  use Rack::Auth::Basic do |user, pass|
    user == ENV['ADMIN_USERNAME'] && pass == ENV['ADMIN_PASSWORD']
  end
end
run Integrity.app
