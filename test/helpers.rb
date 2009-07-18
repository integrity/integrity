$:.unshift File.dirname(__FILE__) + "/../lib", File.dirname(__FILE__)

require "test/unit"
require "rr"
require "dm-sweatshop"
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
  def capture_stdout
    output = StringIO.new
    $stdout = output
    yield
    $stdout = STDOUT
    output
  end
end

class Test::Unit::TestCase
  include RR::Adapters::TestUnit
  include Integrity
  include TestHelper

  before(:all) do
    DataMapper.setup(:default, "sqlite3::memory:")
    require "integrity/migrations"
  end

  before(:each) do
    [Project, Build, Commit, Notifier].each{ |i| i.auto_migrate_down! }
    capture_stdout { Integrity.migrate_db }

    Notifier.available.clear
    Integrity.instance_variable_set(:@config, nil)

    Integrity.config[:log] = "integrity.log"
  end

  after(:each) do
    capture_stdout { Integrity::Migrations.migrate_down! }
  end
end
