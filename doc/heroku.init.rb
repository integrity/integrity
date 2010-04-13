$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "lib"))
gem "data_objects", "= 0.10.1"
require "integrity"

# Uncomment as appropriate for the notifier you want to use
# = Email
require "integrity/notifier/email"
# = IRC
# require "integrity/notifier/irc"
# = Campfire
# require "integrity/notifier/campfire"

Integrity.configure do |c|
  c.database  ENV["DATABASE_URL"]
  c.directory "tmp"
  c.base_url  ENV["BASE_URL"] || "http://myapp.heroku.com"
  c.log       "tmp/integrity.log"
  c.github    ENV["GITHUB_TOKEN"] || "TOKEN"
  c.build_all!
  c.builder :threaded, 5
end

# Specify the tmp dir since Heroku has a read-only filesystem
Integrity::App.configure do |app|
  Sass::Plugin.options[:css_location]      = "#{app.root}/tmp"
  Sass::Plugin.options[:template_location] = app.views
end