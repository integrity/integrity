require "helper"

class ConfiguratorTest < IntegrityTest
  setup { Integrity.auto_branch = false }

  test "builder" do
    Integrity.configure { |c| c.builder(:threaded, 1) }
    assert_respond_to Integrity.builder, :wait!

    assert_raise(ArgumentError) {
      Integrity.configure { |c| c.builder :foo }
    }
  end

  test "directory" do
    Integrity.configure { |c| c.directory "/tmp/builds" }
    assert_equal "/tmp/builds", Integrity.directory.to_s
  end

  test "base_url" do
    Integrity.configure { |c| c.base_url "http://foo.com" }
    assert_equal "http://foo.com", Integrity.base_url.to_s

    Integrity.base_url = nil
    assert_nothing_raised(RuntimeError) { Integrity.app }
  end

  test "log" do
    Integrity.configure { |c| c.log "test.log" }
    assert_equal "test.log", Integrity.logger.
      instance_variable_get(:@logdev).
      instance_variable_get(:@dev).path
  end

  test "github" do
    Integrity.configure { |c| c.github "HOLY_HUB" }
    assert_equal "HOLY_HUB", Integrity::App.github
  end

  test "auto_branch!" do
    begin
      Integrity.configure { |c| c.auto_branch! }
      assert Integrity.auto_branch
    ensure
      Integrity.auto_branch = false
    end
  end
end
