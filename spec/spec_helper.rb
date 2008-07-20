require File.dirname(__FILE__) + "/../lib/integrity"
require "rubygems"
require "spec"

Spec::Runner.configure do |config|
  config.before(:each) do
    DataMapper.setup(:default, "sqlite3::memory:")
    Integrity::Project.auto_migrate!
    Integrity::Build.auto_migrate!
  end
end
