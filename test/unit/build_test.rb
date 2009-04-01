require File.dirname(__FILE__) + '/../helpers'

class BuildTest < Test::Unit::TestCase
  before(:each) do
    RR.reset
  end

  specify "fixture is valid and can be saved" do
    lambda do
      build = Build.gen
      build.save

      build.should be_valid
    end.should change(Build, :count).by(1)
  end

  describe "Properties" do
    before(:each) do
      @build = Build.gen
    end

    it "captures the build's STDOUT/STDERR" do
      @build.output.should_not be_blank
    end

    it "knows if it failed or not" do
      @build.successful = true
      @build.should be_successful
      @build.successful = false
      @build.should be_failed
    end

    it "knows it's status" do
      @build.successful = true
      @build.status.should be(:success)
      @build.successful = false
      @build.status.should be(:failed)
    end

    test "deprecated properties" do
      pending do
        silence_warnings {
          @build.short_commit_identifier.should == @build.commit.short_identifier
          @build.commit_identifier.should == @build.commit.identifier
          @build.commit_author.should     == @build.commit.author
          @build.commit_message.should    == @build.commit.message
          @build.commited_at.should       == @build.commit.committed_at
          @build.project_id.should        == @build.commit.project_id
          @build.should respond_to(:commit_metadata)
        }
      end
    end
  end

  describe "Pending builds" do
    before(:each) do
      3.of { Build.gen(:started_at => nil) }
      2.of { Build.gen(:started_at => Time.mktime(2009, 1, 17, 23, 18)) }
    end

    it "finds builds that need to be built" do
      Build.should have(3).pending
    end
  end

  describe "Queueing a build" do
    before(:each) do
      @commit = Commit.gen
      stub.instance_of(ProjectBuilder).build(@commit)
    end

    it "creates an empty Build" do
      @commit.build.should be_nil
      Build.queue(@commit)
      @commit.build.should_not be_nil
    end

    it "ensures the build is saved" do
      @commit.build.should be_nil
      Build.queue(@commit)

      commit = Commit.first(:identifier => @commit.identifier)
      commit.build.should_not be_nil
    end
  end
end
