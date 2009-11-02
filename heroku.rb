$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), "lib"))
gem "data_objects", "= 0.10.0"
require "integrity"

Integrity.configure { |c|
  c.database  = ENV["DATABASE_URL"]
  c.directory = "tmp"
  c.log       = "tmp/integrity.log"
  c.build_all = true
  c.push    Bobette::GitHub, "SECRET"
  c.builder Integrity::ThreadedBuilder, :size => 2
}

