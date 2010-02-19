require File.join(File.dirname(__FILE__), "..", ".bundle", "environment")

require "test/unit"
require "rr"
require "extlib"
require "dm-sweatshop"
require "context"
require "pending"

require "integrity"
require "fixtures"

begin
  require "ruby-debug"
  require "redgreen"
rescue LoadError
end

class Test::Unit::TestCase
  include RR::Adapters::TestUnit
  include Integrity

  before(:all) do
    Integrity.configure { |c|
      c.database  "sqlite3:test.db"
      c.directory File.expand_path(File.dirname(__FILE__) + "/../tmp")
      c.base_url "http://www.example.com"
      c.log  "test.log"
      c.user "admin"
      c.pass "test"
    }
    Thread.abort_on_exception = true
  end

  before(:each) do DataMapper.auto_migrate! end

  def capture_stdout
    output = StringIO.new
    $stdout = output
    yield
    $stdout = STDOUT
    output
  end

  def assert_change(object, method, difference=1)
    initial_value = object.send(method)
    yield
    assert_equal initial_value + difference, object.send(method)
  end

  def assert_no_change(object, method, &block)
    assert_change(object, method, 0, &block)
  end
end
