$:.unshift File.dirname(__FILE__) + "/../lib", File.dirname(__FILE__)

require "rubygems"

require "test/unit"
require "rr"
require "dm-sweatshop"
require "webrat/sinatra"

gem "jeremymcanally-context"
gem "jeremymcanally-matchy"
gem "jeremymcanally-pending"
require "context"
require "matchy"
require "pending"

require "integrity"
require "integrity/notifier/test/fixtures"

require "helpers/expectations"

begin
  require "ruby-debug"
  require "redgreen"
rescue LoadError
end

module TestHelper
  def ignore_logs!
    Integrity.config[:log] = "/tmp/integrity.test.log"
    Bob.logger = Logger.new("/dev/null")
  end

  def capture_stdout
    output = StringIO.new
    $stdout = output
    yield
    $stdout = STDOUT
    output
  end

  def silence_warnings
    $VERBOSE, v = nil, $VERBOSE
    yield
  ensure
    $VERBOSE = v
  end
end

class Test::Unit::TestCase
  class << self
    alias_method :specify, :test
  end

  include RR::Adapters::TestUnit
  include Integrity
  include TestHelper

  before(:all) do
    DataMapper.setup(:default, "sqlite3::memory:")
    require "integrity/migrations"

    ignore_logs!
  end

  before(:each) do
    [Project, Build, Commit, Notifier].each{ |i| i.auto_migrate_down! }
    capture_stdout { Integrity.migrate_db }
    Notifier.available.clear
    Integrity.instance_variable_set(:@config, nil)
  end

  after(:each) do
    capture_stdout { Integrity::Migrations.migrate_down! }
  end
end
