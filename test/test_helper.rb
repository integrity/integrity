require File.dirname(__FILE__) + "/../lib/integrity"
require File.dirname(__FILE__) + "/test_fixtures"

require "ruby-debug"
require "test/unit"
require "redgreen"
require "context"
require "matchy"
require "rr"

class Test::Unit::TestCase
  class << self
    alias_method :specify, :test
  end
end

# Gives a nicer syntax than declaring TestCase subclasses in tests
def describe(name, &block)
  Test::Unit::TestCase.context(name, &block)
end

module TestHelper
  def setup_and_reset_database!
    DataMapper.setup(:default, "sqlite3::memory:")
    DataMapper.auto_migrate!
  end
end

class Test::Unit::TestCase
  include RR::Adapters::TestUnit
  include TestHelper
end
