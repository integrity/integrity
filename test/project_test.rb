require File.dirname(__FILE__) + '/test_helper'

describe "Project" do
  Project = Integrity::Project

  before(:each) do
    setup_and_reset_database!
    ignore_logs!
  end

  specify "fixture is valid and can be saved" do
    lambda do
      Project.generate.tap do |project|
        project.should be_valid
        project.save
      end
    end.should change(Project, :count).by(1)
  end

  describe "Properties" do
    before(:each) do
      @project = Project.generate
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

      Project.gen(:public => "false").should be_public
      Project.gen(:public => false).should_not be_public
      Project.gen(:public => nil).should_not be_public
    end

    it "has a created_at" do
      @project.created_at.should be_a(DateTime)
    end

    it "has an updated_at" do
      @project.updated_at.should be_a(DateTime)
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
      Project.gen.save

      lambda do
        Project.gen(:name => "Integrity").should_not be_valid
      end.should_not change(Project, :count)
    end
  end

  describe "When finding its previous builds" do
    before(:each) do
      @builds = 5.of { Integrity::Build.gen }
      @project = Project.generate(:builds => @builds)
    end

    it "has 4 previous builds" do
      @project.should have(4).previous_builds
    end

    it "returns the builds ordered chronogicaly (desc) by creation date" do
      builds_sorted_by_creation_date = @builds.sort_by {|build| build.created_at }.reverse
      @project.previous_builds.should == builds_sorted_by_creation_date[1..-1]
    end

    it "excludes the last build" do
      @project.previous_builds.should_not include(@project.last_build)
    end

    it "returns an empty array if it has only one build" do
      project = Project.gen(:builds => 1.of { Integrity::Build.make })
      project.should have(:no).previous_builds
    end

    it "returns an empty array if there are no builds" do
      project = Project.gen(:builds => [])
      project.should have(:no).previous_builds
    end
  end
end
