require File.expand_path("../init", __FILE__)
if ENV['ADMIN_USER'] && ENV['ADMIN_PASSWORD']
  use Rack::Auth::Basic do |user, pass|
    user == ENV['ADMIN_USER'] && pass == ENV['ADMIN_PASSWORD']
  end
end
run Integrity.app
