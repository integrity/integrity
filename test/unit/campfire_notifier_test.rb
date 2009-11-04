require "helper"
require "mocha"
require "integrity/notifier/campfire"

class CampfireNotifierTest < Test::Unit::TestCase
  setup do
    Integrity.configure { |c| c.base_uri = "http://example.org" }
    @config = { "account" => "integrity",
      "use_ssl" => false,
      "room"    => "ci",
      "user"    => "foo",
      "pass"    => "bar",
      "announce_success" => true }
    @notifier = Integrity::Notifier::Campfire
    @room = stub(:speak => nil, :paste => nil, :leave => nil)
  end

  def notifier
    "Campfire"
  end

  test "it registers itself" do
    assert_equal @notifier, Integrity::Notifier.available["Campfire"]
  end

  test "configuration form" do
    pending "Campfire notifier needs better tests" do
      assert provides_option? "account", @config["account"]
      assert provides_option? "use_ssl", @config["use_ssl"]
      assert provides_option? "room",    @config["room"]
      assert provides_option? "user",    @config["user"]
      assert provides_option? "pass",    @config["pass"]
      #assert provides_option? "announce_success", @config["announce_success"]
    end
  end

  test "ssl" do
    @config["use_ssl"] = true

    Tinder::Campfire.expects(:new).with(@config["account"], { :ssl => true }).
      returns(stub(:login => true, :find_room_by_name => @room))

    @notifier.notify_of_build(Integrity::Build.gen, @config)
  end

  test "successful build" do
    build = Integrity::Build.gen(:successful)

    @notifier.any_instance.stubs(:room).at_least_once.returns(@room)
    @room.expects(:speak).with {|v| v.include?(build.commit.short_identifier)}
    @room.expects(:paste).never

    @notifier.notify_of_build(build, @config)
  end

  test "don't announce successes" do
    build = Integrity::Build.gen(:successful)

    @config['announce_success'] = false
    @notifier.any_instance.stubs(:room).at_least_once.returns(@room)
    @room.expects(:speak).never

    @notifier.notify_of_build(build, @config)
  end

  test "failed build" do
    build = Integrity::Build.gen(:failed)

    @notifier.any_instance.stubs(:room).at_least_once.returns(@room)
    @room.expects(:speak).with {|v| v.include?(build.commit.short_identifier)}
    @room.expects(:paste).with { |value|
      value.include?(build.commit.message) &&
        value.include?(build.output)
    }

    @notifier.notify_of_build(build, @config)
  end
end
