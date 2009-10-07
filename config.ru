require File.expand_path("./lib/integrity")

Integrity.configure { |c|
  c.database  = "sqlite3:integrity.db"
  c.directory = "builds"
  c.log       = "integrity.log"
  c.build_all = true

  c.push    Bobette::GitHub, "SECRET"
  c.builder Integrity::ThreadedBuilder, :size => 5
}

run Integrity.app
