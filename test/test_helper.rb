require File.dirname(__FILE__) + "/../lib/integrity"
$LOAD_PATH << File.dirname(__FILE__) + "/helpers"

require "ruby-debug"
require "test/unit"
require "redgreen"
require "context"
require "matchy"
require "rr"
require "mocha"
require "test_fixtures"
require "expectations"

module TestHelper
  def setup_and_reset_database!
    DataMapper.setup(:default, "sqlite3::memory:")
    DataMapper.auto_migrate!
  end
  
  def ignore_logs!
    stub(Integrity).log { nil }
  end
end

class Test::Unit::TestCase
  class << self
    alias_method :specify, :test
  end

  include RR::Adapters::TestUnit
  include TestHelper
end
