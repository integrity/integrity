require "helper"

class ConfiguratorTest < IntegrityTest
  setup do
    Integrity.instance_variable_set(:@config, nil)
  end

  test "builder" do
    Integrity.configure { |c| c.builder = :threaded, 1 }
    assert_respond_to Integrity.config.builder, :wait!

    # TODO
    #Integrity.configure { |c| c.builder = :resque }
    #assert Integrity::ResqueBuilder === Integrity.config.builder

    assert_raise(ArgumentError) {
      Integrity.configure { |c| c.builder = :foo }
    }
  end

  test "directory" do
    Integrity.configure { |c| c.directory = "/tmp/builds" }
    assert_equal "/tmp/builds/foo", Integrity.config.directory.join("foo").to_s
  end

  test "base_url" do
    Integrity.configure { |c| c.base_url = "http://foo.com" }
    assert_equal "foo.com", Integrity.config.base_url.host

    Integrity.configure { |c| c.base_url = nil }
    assert_nothing_raised(RuntimeError) { Integrity.app }
  end

  test "logging" do
    Integrity.configure { |c| c.log = "test.log" }
    assert_equal "test.log", Integrity.config.logger.
      instance_variable_get(:@logdev).
      instance_variable_get(:@dev).path
  end

  test "github" do
    Integrity.configure { |c| c.github_token = "HOLY_HUB" }
    assert_equal "HOLY_HUB", Integrity.config.github_token
    assert Integrity.config.github_enabled?
  end

  test "auto_branch" do
    begin
      Integrity.configure { |c| c.auto_branch = true }
      assert Integrity.config.auto_branch?
    ensure
      Integrity.configure { |c| c.auto_branch = false }
    end
  end

  test "auth" do
    assert ! Integrity.config.protected?

    Integrity.configure { |c| c.username = "a"; c.password = "b" }

    assert Integrity.config.protected?
  end
end
