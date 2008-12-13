require File.dirname(__FILE__) + '/../lib/integrity'
require File.dirname(__FILE__) + '/test_fixtures'

require "ruby-debug"
require "test/unit"
require "redgreen"
require "context"
require "matchy"
require "rr"

class Test::Unit::TestCase
  include RR::Adapters::TestUnit
end

# Gives a nicer syntax than declaring TestCase subclasses in tests
def describe(name, &block)
  Class.new(Test::Unit::TestCase) do
    context(name.to_s, &block)
  end
end
