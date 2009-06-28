require File.dirname(__FILE__) + "/../helpers"
require "helpers/acceptance/textfile_notifier"

class NotifierTest < Test::Unit::TestCase
  test "IRC fixture is valid and can be saved" do
    lambda do
      Notifier.generate(:irc).tap do |project|
        project.should be_valid
        project.save
      end
    end.should change(Project, :count).by(1)
  end

  test "Twitter fixture is valid and can be saved" do
    lambda do
      Notifier.generate(:twitter).tap do |project|
        project.should be_valid
        project.save
      end
    end.should change(Project, :count).by(1)
  end

  describe "Properties" do
    before(:each) do
      @notifier = Notifier.generate(:irc)
    end

    it "has a name" do
      @notifier.name.should == "IRC"
    end

    it "has a config" do
      @notifier.config.should == {:uri => "irc://irc.freenode.net/integrity"}
    end
  end

  describe "Validation" do
    it "requires a name" do
      lambda do
        Notifier.generate(:irc, :name => nil)
      end.should_not change(Notifier, :count)
    end

    it "requires a config" do
      lambda do
        Notifier.generate(:irc, :config => nil)
      end.should_not change(Notifier, :count)
    end

    it "requires a project" do
      lambda do
        Notifier.generate(:irc, :project => nil)
      end.should_not change(Notifier, :count)
    end

    it "requires an unique name in project scope" do
      project = Project.generate
      irc     = Notifier.gen(:irc, :project => project)

      project.tap { |project| project.notifiers << irc }.save

      lambda do
        project.tap { |project| project.notifiers << irc }.save
      end.should_not change(project.notifiers, :count).from(1).to(2)

      lambda { Notifier.gen(:irc) }.should change(Notifier, :count).to(2)
    end
  end

  describe "Registering a notifier" do
    it "registers given notifier class" do
      Notifier.register(Integrity::Notifier::Textfile)

      assert_equal Integrity::Notifier::Textfile,
        Notifier.available["Textfile"]
    end

    it "raises ArgumentError if given class is not a valid notifier" do
      assert_raise(ArgumentError) {
        Notifier.register(Class.new)
      }

      assert Notifier.available.empty?
    end
  end

  it "knows how to notify the world of a build" do
    irc   = Notifier.gen(:irc)
    Notifier.register(Integrity::Notifier::IRC)
    build = Build.gen

    mock(Notifier::IRC).notify_of_build(build, irc.config) { nil }

    irc.notify_of_build(build)
  end

  it "handles notifier timeouts" do
    irc   = Notifier.gen(:irc)
    Notifier.register(Integrity::Notifier::IRC)
    build = Build.gen

    stub.instance_of(Notifier::IRC).deliver! { raise Timeout::Error }
    mock(Integrity).log(anything)
    mock(Integrity).log("Integrity::Notifier::IRC notifier timed out") { nil }

    irc.notify_of_build(build)
  end
end
