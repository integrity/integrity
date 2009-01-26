require File.dirname(__FILE__) + "/../helpers"

class ProjectTest < Test::Unit::TestCase
  before(:each) do
    RR.reset
    setup_and_reset_database!
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
  
  describe "Finding public or private projects" do
    before(:each) do
      @public_project = Project.gen(:public => true)
      @private_project = Project.gen(:public => false)
    end
    
    it "finds only public projects if the condition passed is false" do
      projects = Project.only_public_unless(false)
      projects.should_not include(@private_project)
      projects.should include(@public_project)
    end
    
    it "finds both private and public projects if the condition passed is true" do
      projects = Project.only_public_unless(true)
      projects.should include(@private_project)
      projects.should include(@public_project)
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
  
    it "destroys itself and tell ProjectBuilder to delete the code from disk" do
      lambda do
        stub.instance_of(ProjectBuilder).delete_code
        @project.destroy
      end.should change(Project, :count).by(-1)
    end
  
    it "destroys its builds" do
      lambda do
        @project.destroy
      end.should change(Commit, :count).by(-7)
    end
  end
  
  describe "When retrieving state about its notifier" do
    before(:each) do
      @project = Project.generate
      @irc     = Notifier.generate(:irc)
    end
  
    specify "#config_for returns given notifier's configuration" do
      @project.update_attributes(:notifiers => [@irc])
      @project.config_for("IRC").should == {:uri => "irc://irc.freenode.net/integrity"}
    end
  
    specify "#config_for returns an empty hash if no such notifier" do
      @project.config_for("IRC").should == {}
    end
  
    specify "#notifies? is true if it uses the given notifier" do
      @project.update_attributes(:notifiers => [@irc])
      @project.notifies?("IRC").should == true
    end
  
    specify "#notifies? is false if it doesnt use the given notifier" do
      @project.update_attributes(:notifiers => [])
  
      @project.notifies?("IRC").should == false
      @project.notifies?("UndefinedNotifier").should == false
    end
  end

  describe "When building a commit" do
    before(:each) do
      @commits = 2.of { Commit.gen }
      @project = Project.gen(:integrity, :commits => @commits)
      stub.instance_of(ProjectBuilder).build { nil }
    end
  
    it "gets the specified commit and creates a pending build for it" do
      commit = @commits.last

      lambda {
        @project.build(commit.identifier)
      }.should change(Build, :count).by(1)
      
      build = Build.all.last
      build.commit.should be(commit)
      build.should be_pending
      
      commit.should be_pending
    end
    
    it "creates an empty commit with the head of the project if passed 'HEAD' (the default)" do
      mock(@project).head_of_remote_repo { "FOOBAR" }
      
      lambda {
        @project.build("HEAD")
      }.should change(Commit, :count).by(1)
      
      build = Build.all.last
      build.commit.should be(@project.last_commit)
      
      @project.last_commit.should be_pending
      @project.last_commit.identifier.should be("FOOBAR")

      @project.last_commit.author.name.should == "<Commit author not loaded>"
      @project.last_commit.message.should == "<Commit message not loaded>"
    end
  end
end
