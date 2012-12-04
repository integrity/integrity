require File.expand_path("../init", __FILE__)

if ENV['ADMIN_USERNAME'] && ENV['ADMIN_PASSWORD']
  required_username = ENV['ADMIN_USERNAME']
  required_password = ENV['ADMIN_PASSWORD']
elsif ENV['ADMIN_USER'] && ENV['ADMIN_PASS']
  # Obsolete - for compatibility only
  required_username = ENV['ADMIN_USER']
  required_password = ENV['ADMIN_PASS']
else
  required_username = required_password = nil
end
if required_username
  use Rack::Auth::Basic do |username, password|
    username == required_username && password == required_password
  end
end

run Integrity.app
