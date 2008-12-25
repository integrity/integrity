$LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__) + "/../../lib"))

require "test/unit"
require "webrat/sinatra"
require File.dirname(__FILE__) + "/sinatra/app"

class WebratWithSinatraAndTestUnitTest < Test::Unit::TestCase
  def test_it_works_with_test_unit_too
    get "/"
    assert_equal body, "hello world"
    assert_equal status, 200
  end
end
