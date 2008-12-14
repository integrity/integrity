require File.dirname(__FILE__) + '/test_helper'

describe "Project" do
  Project = Integrity::Project

  before(:each) do
    setup_and_reset_database!
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

    it "has a public flag" do
      # TODO: rename Project#public property to visibility
      # TODO: and have utility method to query its state instead
      @project.should be_public
    end

    specify "public flag default to true" do
      Project.new.should be_public
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

  describe "Permalink" do
    it "is downcased" do
      Project.gen(:name => "EEEK").permalink.should == "eeek"
    end

    it "replaces ''s' with 's'" do
      Project.gen(:name => "foca's").permalink.should == "focas"
    end

    it "replaces '&' by 'and'" do
      Project.gen(:name => "foca&sr").permalink.should == "focaandsr"
    end

    it "replaces non alphanumeric characters by '-'" do
      Project.gen(:name => "foo bar").permalink.should == "foo-bar"
    end

    it "ensures it don't ends up with multiple dashes" do
      Project.gen(:name => "foca! & sr").permalink.should == "foca-and-sr"
    end

    it "ensures it has no dash at the end" do
      Project.gen(:name => "foo bar!!?").permalink.should == "foo-bar"
    end

    it "updates the permalink when the name changes" do
      Project.gen.tap do |project|
        project.permalink.should == "integrity"
        project.name = "some project"
        project.save
        project.permalink.should == "some-project"
      end
    end
  end

  describe "Visibility" do
    it "is public for any non false value" do
      Project.gen(:public => "false").should be_public
      Project.gen(:public => "nil").should be_public
    end

    it "is not public when set to false" do
      Project.gen(:public => false).should_not be_public
    end

    it "is not public when set to nil" do
      Project.gen(:public => nil).should_not be_public
    end
  end

  describe "When finding its previous builds" do
    before(:each) do
      @builds = 5.of { Integrity::Build.gen }
      @project = Project.generate(:builds => @builds)
    end

    it "has 5 builds" do
      # TODO: write a matcher for this
      @project.builds.count.should == 5
    end

    it "has 4 previous builds" do
      # TODO: write a matcher for this
      @project.previous_builds.count.should == 4
    end

    it "returns the builds ordered chronogicaly (desc) by creation date" do
      # TODO: not sure I am doing it right here...
      @builds.sort_by { |build| build.created_at }
      @builds.shift
      @builds.each_with_index do |build, index|
        @project.previous_builds[index].should == build
      end
    end

    it "excludes the last build" do
      # TODO: uh?
      #@project.previous_builds.should_not include(@project.last_build)
    end

    it "returns an empty array if it has only one build" do
      Project.gen(:builds => 1.of { Integrity::Build.make }).previous_builds.should be_empty
    end

    it "returns an empty array if there are no builds" do
      Project.gen(:builds => []).previous_builds.should be_empty
    end
  end
end
