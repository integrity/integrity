require "rubygems"
gem "integrity"
require "integrity"

Integrity.config = {
  :database_uri     => ENV["DATABASE_URL"],
  :export_directory => File.dirname(__FILE__) + "/tmp",
  :log              => File.dirname(__FILE__) + "/log/integrity.log"
}

Integrity.new
