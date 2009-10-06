module Haml;module Version;@@version="2.2.2" end end if ENV["RIPDIR"]

require "test/unit"
require "rr"
require "extlib"
require "dm-sweatshop"
require "context"
require "matchy"
require "pending"

require "integrity"
require "integrity/notifier/test/fixtures"

require "helper/expectations"

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

  def assert_change(object, method, difference=1)
    initial_value = object.send(method)
    yield
    assert_equal initial_value + difference, object.send(method)
  end

  def assert_no_change(object, method, &block)
    assert_change(object, method, 0, &block)
  end
end

class Test::Unit::TestCase
  include RR::Adapters::TestUnit
  include Integrity
  include TestHelper

  before(:all) do
    Integrity.configure { |c|
      c.database  = "sqlite3::memory:"
      c.directory = File.expand_path(File.dirname(__FILE__) + "/../../../tmp")
      c.log  = "/dev/null"
      c.user = "admin"
      c.pass = "test"
    }
  end

  before(:each) do
    DataMapper.auto_migrate!
  end
end
