require "test/unit"
require "rr"
require "extlib"
require "dm-sweatshop"
require "contest"

require "integrity"
require "fixtures"

begin
  require "ruby-debug"
  require "redgreen"
rescue LoadError
end

class IntegrityTest < Test::Unit::TestCase
  include RR::Adapters::TestUnit
  include Integrity

  def setup
    Integrity.configure { |c|
      c.database  "sqlite3:test.db"
      c.directory File.expand_path(File.dirname(__FILE__) + "/../tmp")
      c.base_url "http://www.example.com"
      c.log  "test.log"
      c.user "admin"
      c.pass "test"
    }
    Thread.abort_on_exception = true
    DataMapper.auto_migrate!
  end

  class << self
    alias_method :it, :test
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
