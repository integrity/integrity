$LOAD_PATH.unshift(File.expand_path("../lib", __FILE__))

begin
  require ".bundle/environment"
rescue LoadError
  require "bundler/setup"
end

require "integrity"

# Uncomment as appropriate for the notifier you want to use
# = Email
# require "integrity/notifier/email"
# = Campfire
# require "integrity/notifier/campfire"
# = TCP
# require "integrity/notifier/tcp"
# = HTTP
# require "integrity/notifier/http"
# = Notifo
# require "integrity/notifier/notifo"
# = AMQP
# require "integrity/notifier/amqp"
# = Shell
# require "integrity/notifier/shell"
# = Co-op
# require "integrity/notifier/coop"

Integrity.configure do |c|
  c.database                    = "sqlite3:integrity.db"
  c.directory                   = "builds"
  c.base_url                    = "http://ci.example.org"
  c.log                         = "integrity.log"
  c.github_token                = "SECRET"
  c.build_all                   = true
  c.trim_builds                 = false
  c.builder                     = :threaded, 5
  c.project_default_build_count = 10
end
