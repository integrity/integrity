require File.dirname(__FILE__) + "/../lib/integrity"
$:.unshift Integrity.root / "vendor/rspec_hpricot_matchers/lib"

require "spec"
require 'spec/interop/test'
require 'sinatra'
require 'sinatra/test/unit'
require "rspec_hpricot_matchers"

Spec::Runner.configure do |config|
  config.include RspecHpricotMatchers

  config.before(:each) do
    DataMapper.setup(:default, "sqlite3::memory:")
    Integrity::Project.auto_migrate!
    Integrity::Build.auto_migrate!
  end
end
