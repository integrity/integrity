require File.dirname(__FILE__) + "/../lib/integrity"
require "rubygems"
require "spec"

DataMapper.setup(:default, "sqlite3::memory:")
Integrity::Project.auto_migrate!
Integrity::Build.auto_migrate!