require File.dirname(__FILE__) + "/../helpers"

class NotifierTest < Test::Unit::TestCase
  before(:each) do 
    setup_and_reset_database!
  end

  specify "IRC fixture is valid and can be saved" do
    lambda do
      Notifier.generate(:irc).tap do |project|
        project.should be_valid
        project.save
      end
    end.should change(Project, :count).by(1)
  end

  specify "Twitter fixture is valid and can be saved" do
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

  it "knows which notifiers are available" do
    Notifier.gen(:twitter)
    Notifier.should have(2).available
    Notifier.available.should include(Integrity::Notifier::IRC)
    Notifier.available.should include(Integrity::Notifier::Twitter)
  end

  it "knows how to notify the world of a build" do
    irc   = Notifier.generate(:irc)
    build = Integrity::Build.generate
    Notifier::IRC.expects(:notify_of_build).with(build, irc.config)
    irc.notify_of_build(build)
  end

  describe "Enabling a list of notifiers for a project" do
    it "creates new notifiers for the project" do
      project = Project.generate
      lambda do
        project.enable_notifiers(["IRC", "Twitter"],
          {"IRC" => {"uri" => "irc://irc.freenode.net/integrity"},
           "Twitter" => {"username" => "john"}})
      end.should change(project.notifiers, :count).from(0).to(2)
    end

    it "deletes all of previous notifiers" do
      project = Project.generate(:notifiers => [Notifier.gen(:irc), Notifier.gen(:twitter)])
      lambda do
        project.enable_notifiers("IRC", {"IRC" => {:foo => "bar"}})
        project.reload
      end.should change(project.notifiers, :count).from(2).to(1)
    end

    it "does nothing if given nil as the list of notifiers to enable" do
      lambda { Project.gen.enable_notifiers(nil, {}) }.should_not change(Notifier, :count)
    end

    it "doesn't destroy any of the other notifiers that exist for other projects" do
      irc = Notifier.generate(:irc)

      project = Project.gen
      project.enable_notifiers("IRC", {"IRC" => irc.config})

      lambda do
        Project.gen.enable_notifiers("IRC", {"IRC" => irc.config})
      end.should_not change(project.notifiers, :count)
    end
  end
  
  it "requires notifier classes to implement Notifier.to_haml and Notifier#deliver!" do
    class Blah < Notifier::Base; end
    lambda { Blah.to_haml }.should raise_error(NoMethodError)
    lambda { Blah.new(Build.gen, {}).deliver! }.should raise_error(NoMethodError)
  end
end
