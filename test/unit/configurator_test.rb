require "helper"

class ConfiguratorTest < Test::Unit::TestCase
  test "builder" do
    Integrity.configure { |c| c.builder(:threaded, 1) }
    assert_respond_to Integrity.builder, :wait!

    assert_raise(ArgumentError) {
      Integrity.configure { |c| c.builder :foo }
    }
  end

  test "directory" do
    Integrity.configure { |c| c.directory = "/tmp/builds" }
    assert_equal "/tmp/builds", Integrity.directory.to_s
  end

  test "base_uri" do
    Integrity.configure { |c| c.base_uri = "http://example.org" }
    assert_equal "http://example.org", Integrity.base_uri.to_s
  end

  test "log" do
    Integrity.configure { |c| c.log = "test.log" }
    assert_equal "test.log", Integrity.logger.
      instance_variable_get(:@logdev).
      instance_variable_get(:@dev).path
  end
end
