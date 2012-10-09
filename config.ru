require File.expand_path("../init", __FILE__)
use Rack::Auth::Basic do |user, pass|
  # If ENV['ADMIN_USER'] and ENV['ADMIN_PASSWORD'] exist, use those, otherwise use "admin" / "secret"
  user == (ENV['ADMIN_USER'] || "admin") && pass == (ENV['ADMIN_PASSWORD'] || "secret")
end
run Integrity.app
