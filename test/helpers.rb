require File.dirname(__FILE__) + "/../lib/integrity"

require "test/unit"
require "redgreen"
require "context"
require "matchy"
require "rr"
require "mocha"
require "ruby-debug"

require File.dirname(__FILE__) / "helpers" / "expectations"
require File.dirname(__FILE__) / "helpers" / "fixtures"
require File.dirname(__FILE__) / "helpers" / "acceptance"

module TestHelper
  def setup_and_reset_database!
    DataMapper.setup(:default, "sqlite3::memory:")
    DataMapper.auto_migrate!
  end
  
  def ignore_logs!
    stub(Integrity).log { nil }
  end

  def response
    @response
  end
end

class Test::Unit::TestCase
  class << self
    alias_method :specify, :test
  end

  include RR::Adapters::TestUnit
  include Integrity
  include TestHelper
end

