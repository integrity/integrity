require  File.dirname(__FILE__) + '/spec_helper'

describe Integrity::Builder do
  def mock_project(messages={})
    @project ||= begin
      uri = Addressable::URI.parse("git://github.com/foca/integrity.git")
      messages = { :uri => uri, :command => "rake", :branch => "master" }.merge(messages)
      mock("project", messages)
    end
  end
  
  def mock_build(messages={})
    @build ||= begin
      messages = {
        :project => mock_project,
        :commit_metadata= => {},
        :commit_identifier= => nil,
        :output= => nil,
        :output => "",
        :error => "",
        :successful= => true,
        :save => true
      }.merge(messages)
      mock("build", messages)
    end
  end
  
  def mock_scm(messages={})
    @scm ||= begin
      scm = mock "scm", { :with_revision => true }.merge(messages)

      scm.stub!(:commit_identifier).with('6eba34d94b74fe68b96e35450fadf241113e44fc').and_return('6eba34d94b74fe68b96e35450fadf241113e44fc')
      scm.stub!(:commit_metadata).with('6eba34d94b74fe68b96e35450fadf241113e44fc').and_return(
        :author  => 'Simon Rozet <simon@rozet.name>',
        :message => 'A commit message',
        :date    => Time.parse('Mon Jul 21 15:24:34 2008 +0200')
      )
      
      scm
    end
  end
  
  before do
    Integrity.stub!(:config).and_return(:export_directory => "/var/integrity/exports")
    Integrity::Builder.class_eval { public :export_directory, :run_build_script }
  end
  
  describe 'When initializing' do
    it 'should instantiate a new Build model' do
      Integrity::SCM.stub!(:new).and_return(mock_scm)
      Integrity::Build.should_receive(:new).and_return(@build)
      Integrity::Builder.new(mock_project)
    end

    it "should creates a new SCM object using the given URI's and given options and pass it the build" do
      Integrity::Build.stub!(:new).and_return(mock_build)
      Integrity::SCM.should_receive(:new).with(mock_project.uri, "master", "/var/integrity/exports/foca-integrity-master")
      Integrity::Builder.new(mock_project)
    end
  end

  before(:each) do
    Integrity::SCM.stub!(:new).and_return(mock_scm)
    Integrity::Build.stub!(:new).and_return(mock_build)
    @builder = Integrity::Builder.new(mock_project)
  end

  describe "Calculating the export directory" do
    it "should start with the base export directory set in the global options" do
      @builder.export_directory.should =~ %r(^/var/integrity/exports)
    end
    
    it "should use the path to the repo in this directory, changing slashes for hyphens" do
      @builder.export_directory.should =~ %r(foca-integrity-master$)
    end
  end
  
  describe "When building a specific commit" do
    before { @builder.stub!(:run_build_script) }
    
    it "should fetch the latest code from the scm and run the build script" do
      mock_scm.should_receive(:with_revision).
        with('6eba34d94b74fe68b96e35450fadf241113e44fc').and_yield do
          @builder.should_receive(:run_build_script)
      end
      @builder.build('6eba34d94b74fe68b96e35450fadf241113e44fc')
    end

    it "should assign the head (minus the identifier) of the SCM as the commit metadata in the build" do
      metadata = mock_scm.commit_metadata('6eba34d94b74fe68b96e35450fadf241113e44fc')
      mock_build.should_receive(:commit_metadata=).with(metadata)
      @builder.build('6eba34d94b74fe68b96e35450fadf241113e44fc')
    end

    it "should assign the commit identifier of the SCM's head as the commit identifier in the build" do
      mock_build.should_receive(:commit_identifier=).with '6eba34d94b74fe68b96e35450fadf241113e44fc'
      @builder.build('6eba34d94b74fe68b96e35450fadf241113e44fc')
    end
    
    it "should save the build to the database" do
      mock_build.should_receive(:save)
      @builder.build('6eba34d94b74fe68b96e35450fadf241113e44fc')
    end
    
    describe "when there's an error" do
      before { mock_scm.stub!(:with_revision).and_raise(RuntimeError) }
      
      it "should still save the build" do
        lambda {
          mock_build.should_receive(:save)
          @builder.build('6eba34d94b74fe68b96e35450fadf241113e44fc')
        }.should raise_error(RuntimeError)
      end
      
      it "should still save in what commit this happened" do
        lambda {
          mock_build.should_receive(:commit_identifier=).with('6eba34d94b74fe68b96e35450fadf241113e44fc')
          @builder.build('6eba34d94b74fe68b96e35450fadf241113e44fc')
        }.should raise_error(RuntimeError)
      end

      it "should still save the commit metadata" do
        lambda {
          metadata = mock_scm.commit_metadata('6eba34d94b74fe68b96e35450fadf241113e44fc')
          mock_build.should_receive(:commit_metadata=).with(metadata)
          @builder.build('6eba34d94b74fe68b96e35450fadf241113e44fc')
        }.should raise_error(RuntimeError)
      end
    end
  end
  
  describe "When running the command" do
    before do
      @pipe = mock("pipe", :read => "output and errors")
      IO.stub!(:popen).and_yield(@pipe)
      $?.stub!(:success?).and_return(true)
    end
    
    it "should run the build_script" do
      IO.should_receive(:popen).with("(rake) 2>&1", "r")
      @builder.run_build_script
    end
    
    it "should write stdout to the build's output log" do
      mock_build.should_receive(:output=).with("output and errors")
      @builder.run_build_script
    end
    
    it "should set the build status to 'successful' if the command executes correctly" do
      $?.should_receive(:success?).and_return(true)
      mock_build.should_receive(:successful=).with(true)
      @builder.run_build_script
    end
    
    it "should set the build status to 'failed' if the command fails" do
      $?.should_receive(:success?).and_return(false)
      mock_build.should_receive(:successful=).with(false)
      @builder.run_build_script
    end
  end
  
  describe "When deleting the code for a project" do
    it "should remove the directory from disk" do
      FileUtils.should_receive(:rm_r).with("/var/integrity/exports/foca-integrity-master")
      @builder.delete_code
    end
    
    it "should not complain if the directory isn't there (e.g, a project with no builds)" do
      FileUtils.stub!(:rm_r).and_raise(Errno::ENOENT)
      lambda { @builder.delete_code }.should_not raise_error
    end
  end
end
