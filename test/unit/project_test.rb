require File.dirname(__FILE__) + "/../helpers"

class ProjectTest < Test::Unit::TestCase
  before(:each) do
    RR.reset
    ignore_logs!
  end

  specify "default fixture is valid and can be saved" do
    lambda do
      Project.generate.tap do |project|
        project.should be_valid
        project.save
      end
    end.should change(Project, :count).by(1)
  end

  specify "integrity fixture is valid and can be saved" do
    lambda do
      Project.generate(:integrity).tap do |project|
        project.should be_valid
        project.save
      end
    end.should change(Project, :count).by(1)
  end

  describe "Properties" do
    before(:each) do
      @project = Project.generate(:integrity)
    end

    it "has a name" do
      @project.name.should == "Integrity"
    end

    it "has a permalink" do
      @project.permalink.should == "integrity"

      @project.tap do |project|
        project.name = "foo's bar/baz and BACON?!"
        project.save
      end.permalink.should == "foos-bar-baz-and-bacon"
    end

    it "has an URI" do
      @project.uri.should == Addressable::URI.parse("git://github.com/foca/integrity.git")
    end

    it "has a branch" do
      @project.branch.should == "master"
    end

    specify "branch defaults to master" do
      Project.new.branch.should == "master"
    end

    it "has a command" do
      # TODO: rename to build_command
      @project.command.should == "rake"
    end

    specify "command defaults to 'rake'" do
      Project.new.command.should == "rake"
    end

    it "has a building flag" do
      @project.should_not be_building
    end

    specify "building flag default to false" do
      Project.new.should_not be_building
    end

    it "knows it's visibility" do
      # TODO: rename Project#public property to visibility
      # TODO: and have utility method to query its state instead

      Project.new.should be_public

      @project.should be_public
      @project.tap { |p| p.public = "1" }.should be_public
      @project.tap { |p| p.public = "0" }.should_not be_public

      Project.gen(:public => "false").should be_public
      Project.gen(:public => "true").should be_public
      Project.gen(:public => false).should_not be_public
      Project.gen(:public => nil).should_not be_public
    end

    it "has a created_at" do
      @project.created_at.should be_a(DateTime)
    end

    it "has an updated_at" do
      @project.updated_at.should be_a(DateTime)
    end

    it "knows it's status" do
      Project.gen(:commits => 1.of{ Commit.gen(:successful) }).status.should == :success
      Project.gen(:commits => 2.of{ Commit.gen(:successful) }).status.should == :success
      Project.gen(:commits => 2.of{ Commit.gen(:failed) }).status.should == :failed
      Project.gen(:commits => 1.of{ Commit.gen(:pending) }).status.should == :pending
      Project.gen(:commits => []).status.should be_nil
    end

    it "knows it's last build" do
      Project.gen(:commits => []).last_commit.should be_nil

      commits = 5.of { Commit.gen(:successful) }
      project = Project.gen(:commits => commits)
      project.last_commit.should == commits.sort_by {|c| c.committed_at }.last
    end
  end

  describe "Validation" do
    it "requires a name" do
      lambda do
        Project.gen(:name => nil).should_not be_valid
      end.should_not change(Project, :count)
    end

    it "requires an URI" do
      lambda do
        Project.gen(:uri => nil).should_not be_valid
      end.should_not change(Project, :count)
    end

    it "requires a branch" do
      lambda do
        Project.gen(:branch => nil).should_not be_valid
      end.should_not change(Project, :count)
    end

    it "requires a command" do
      lambda do
        Project.gen(:command => nil).should_not be_valid
      end.should_not change(Project, :count)
    end

    it "ensures its name is unique" do
      Project.gen(:name => "Integrity")
      lambda do
        Project.gen(:name => "Integrity").should_not be_valid
      end.should_not change(Project, :count)
    end
  end

  describe "Finding any project" do
    before(:each) do
      @rails   = Project.gen(:name => "rails",   :public => true)
      @merb    = Project.gen(:name => "merb",    :public => true)
      @sinatra = Project.gen(:name => "sinatra", :public => true)
      @camping = Project.gen(:name => "camping", :public => false)
    end

    it "should always be ordered by name" do
      Project.all.should == [@camping, @merb, @rails, @sinatra]
      Project.all(:public => true).should == [@merb, @rails, @sinatra]
    end
  end

  describe "When finding its previous builds" do
    before(:each) do
      @project = Project.generate(:commits => 5.of { Commit.gen })
      @commits = @project.commits.sort_by {|c| c.committed_at }.reverse
    end

    it "has 4 previous builds" do
      @project.should have(4).previous_commits
    end

    it "returns the builds ordered chronogicaly (desc) by creation date" do
      @project.previous_commits.should == @commits[1..-1]
    end

    it "excludes the last build" do
      @project.previous_commits.should_not include(@project.last_commit)
    end

    it "returns an empty array if it has only one build" do
      project = Project.gen(:commits => 1.of { Integrity::Commit.gen })
      project.should have(:no).previous_commits
    end

    it "returns an empty array if there are no builds" do
      project = Project.gen(:commits => [])
      project.should have(:no).previous_commits
    end
  end

  describe "When getting destroyed" do
    before(:each) do
      @commits  = 7.of { Commit.gen }
      @project = Project.generate(:commits => @commits)
    end

    it "destroys itself" do
      lambda do
        @project.destroy
      end.should change(Project, :count).by(-1)
    end

    it "destroys its builds" do
      lambda do
        @project.destroy
      end.should change(Commit, :count).by(-7)
    end
  end

  describe "When updating its notifiers" do
    setup do
      twitter = Notifier.gen(:twitter, :enabled => true)
      irc     = Notifier.gen(:irc,     :enabled => false)

      @project = Project.gen(:notifiers => [twitter, irc])
    end

    it "creates and enable the given notifiers" do
      Notifier.all.destroy!

      project = Project.gen
      project.update_notifiers(["IRC", "Twitter"],
          {"IRC"     => {"uri" => "irc://irc.freenode.net/integrity"},
           "Twitter" => {"username" => "john"}})

      assert_equal 2,         Notifier.count
      assert_equal 2,         project.enabled_notifiers.count

      notifier_names = project.notifiers.map { |n| n.name }
      assert notifier_names.include?("IRC")
      assert notifier_names.include?("Twitter")

      project.update_notifiers(["Twitter"],
          {"IRC"     => {"uri" => "irc://irc.freenode.net/integrity"},
           "Twitter" => {"username" => "john"}})

      assert_equal 2, Notifier.count
      assert ! project.notifies?("IRC")
      assert   project.notifies?("Twitter")
    end

    it "creates notifiers present in config even when they're disabled" do
      @project.update_notifiers(["IRC"],
        {"IRC"     => {"uri" => "irc://irc.freenode.net/integrity"},
         "Twitter" => {"username" => "john"}})

      assert_equal 2, @project.notifiers.count
    end

    it "disables notifiers that are not included in the list" do
      @project.update_notifiers(["IRC"],
          {"IRC"     => {"uri" => "irc://irc.freenode.net/integrity"},
           "Twitter" => {"username" => "john"}})

      @project.update_notifiers(["IRC"],
        {"IRC"     => {"uri" => "irc://irc.freenode.net/integrity"}})

      assert ! @project.notifiers.first(:name => "Twitter").enabled?
      assert   @project.notifiers.first(:name => "IRC").enabled?
    end

    it "preserves config of notifiers that are being disabled" do
      @project.update_notifiers(["IRC"],
        {"IRC"     => {"uri" => "irc://irc.freenode.net/integrity"},
          "Twitter" => {"username" => "john"}})

      assert_equal "john",
        @project.notifiers.first(:name => "Twitter").config["username"]
    end

    it "does nothing if given nil as the list of notifiers to enable" do
      lambda { Project.gen.update_notifiers(nil, {}) }.should_not change(Notifier, :count)
    end

    it "doesn't destroy any of the other notifiers that exist for other projects" do
      irc = Notifier.generate(:irc)

      project = Project.gen
      project.update_notifiers("IRC", {"IRC" => irc.config})

      lambda {
        Project.gen.update_notifiers("IRC", {"IRC" => irc.config})
      }.should_not change(project.notifiers, :count)
    end
  end

  describe "When retrieving state about its notifier" do
    before(:each) do
      @project = Project.gen
      @irc     = Notifier.generate(:irc)
    end

    it "knows which notifiers are enabled" do
      notifiers = [Notifier.gen(:irc, :enabled => false),
        Notifier.gen(:twitter, :enabled => true)]
      project = Project.gen(:notifiers => notifiers)

      assert_equal 1, project.enabled_notifiers.size
    end

    specify "#config_for returns given notifier's configuration" do
      @project.update_attributes(:notifiers => [@irc])
      @project.config_for("IRC").should == {:uri => "irc://irc.freenode.net/integrity"}
    end

    specify "#config_for returns an empty hash for unknown notifier" do
      @project.config_for("IRC").should == {}
    end

    specify "#notifies? is true if the notifier exists and is enabled" do
      assert ! @project.notifies?("UndefinedNotifier")

      @project.update_attributes(:notifiers =>
        [ Notifier.gen(:irc, :enabled     => true),
          Notifier.gen(:twitter, :enabled => false) ])

      assert @project.notifies?("IRC")
      assert ! @project.notifies?("Twitter")
    end
  end
end
