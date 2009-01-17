require File.dirname(__FILE__) + "/../helpers"

class ProjectBuilderTest < Test::Unit::TestCase
  before(:all) do
    Integrity.config[:export_directory] = File.dirname(__FILE__)
    @directory = Integrity.config[:export_directory] + "/foca-integrity-master"
    FileUtils.mkdir(@directory)
  end

  after(:all) do
    FileUtils.rm_rf(@directory)
  end

  before(:each) do
    setup_and_reset_database!
    @project = Integrity::Project.generate(:integrity, :command => "echo 'output!'")
    ignore_logs!
  end

  it "creates a new SCM with given project's uri, branch and export_directory" do
    SCM::Git.expects(:new).with(@project.uri, @project.branch, @directory)
    ProjectBuilder.new(@project)
  end

  describe "When building" do
    it "creates a new build" do
      lambda do
        SCM::Git.any_instance.expects(:with_revision).with("commit").yields
        SCM::Git.any_instance.expects(:commit_identifier).with("commit").returns("commit identifier")
        SCM::Git.any_instance.expects(:commit_metadata).with("commit").returns(:meta => "data")

        build = ProjectBuilder.new(@project).build("commit")
        build.commit_identifier.should  == "commit identifier"
        build.commit_metadata.should    == {:meta => "data"}
        build.output.should == "output!\n"
        build.should be_successful
      end.should change(@project.builds, :count).by(1)
    end

    it "creates a new build even if something horrible happens" do
      lambda do
        lambda do
          SCM::Git.any_instance.expects(:with_revision).with("commit").raises
          SCM::Git.any_instance.expects(:commit_identifier).with("commit").returns("commit identifier")
          SCM::Git.any_instance.expects(:commit_metadata).with("commit").returns(:meta => "data")

          build = ProjectBuilder.new(@project).build("commit")
          build.commit_identifier.should  == "commit identifier"
          build.commit_metadata.should    == {:meta => "data"}
        end.should change(@project.builds, :count).by(1)
      end.should raise_error
    end

    it "sets the build status to failure when the build command exits with a non-zero status" do
      @project.update_attributes(:command => "exit 1")
      SCM::Git.any_instance.expects(:with_revision).with("HEAD").yields
      build = ProjectBuilder.new(@project).build("HEAD")
      build.should be_failed
    end

    it "sets the build status to failure when the build command exits with a zero status" do
      @project.update_attributes(:command => "exit 0")
      SCM::Git.any_instance.expects(:with_revision).with("HEAD").yields
      build = ProjectBuilder.new(@project).build("HEAD")
      build.should be_successful
    end

    it "runs the command in the export directory" do
      @project.update_attributes(:command => "cat foo.txt")
      File.open(@directory + "/foo.txt", "w") { |file| file << "bar!" }
      SCM::Git.any_instance.expects(:with_revision).with("HEAD").yields

      build = ProjectBuilder.new(@project).build("HEAD")
      build.output.should == "bar!"
    end

    it "captures both stdout and stderr" do
      @project.update_attributes(:command => "echo foo through out && echo bar through err 1>&2")
      SCM::Git.any_instance.expects(:with_revision).with("HEAD").yields

      build = ProjectBuilder.new(@project).build("HEAD")
      build.output.should == "foo through out\nbar through err\n"
    end
  end

  describe "When deleting the code from disk" do
    it "destroys the directory" do
      lambda do
        ProjectBuilder.new(@project).delete_code
      end.should change(Pathname.new(@directory), :directory?).from(true).to(false)
    end

    it "don't complains if the directory doesn't exists" do
      Pathname.new(@directory).should_not be_directory
      lambda { ProjectBuilder.new(@project).delete_code }.should_not raise_error
    end
  end
end
