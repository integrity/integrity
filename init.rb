$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "lib"))

require "integrity"

# Uncomment as appropriate for the notifier you want to use
# = Email
# require "integrity/notifier/email"
# = IRC
# require "integrity/notifier/irc"
# = Campfire
# require "integrity/notifier/campfire"

Integrity.configure { |c|
  c.database  = "sqlite3:integrity.db"
  c.directory = "builds"
  c.log       = "integrity.log"
  c.build_all = true

  c.push    Bobette::GitHub, "SECRET"
  c.builder Integrity::ThreadedBuilder, :size => 5
}
