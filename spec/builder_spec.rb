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
      messages = { :project => mock_project, :commit= => {}, :output= => nil, :output => "", :error => "", :successful= => true, :save => true }.merge(messages)
      mock("build", messages)
    end
  end
  
  def mock_scm(messages={})
    @scm ||= begin
      messages = { :with_latest_code => true, :head => Hash.new }.merge(messages)
      mock("scm", messages)
    end
  end
  
  before do
    Integrity.stub!(:config).and_return(:export_directory => "/var/integrity/exports")
    Integrity::Builder.class_eval { public :export_directory, :run_build_script, :successful_execution? }
  end
  
  describe 'When initializing' do
    it 'should instantiate a new Build model' do
      Integrity::SCM.stub!(:new).and_return(mock_scm)
      Integrity::Build.should_receive(:new).and_return(@build)
      Integrity::Builder.new(mock_project)
    end

    it "should creates a new SCM object using the given URI's and given options and pass it the build" do
      Integrity::Build.stub!(:new).and_return(mock_build)
      Integrity::SCM.should_receive(:new).with(mock_project.uri, "master", "/var/integrity/exports/foca-integrity")
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
      @builder.export_directory.should =~ %r(foca-integrity$)
    end
  end
  
  describe "When building" do
    before { @builder.stub!(:run_build_script) }
    
    it "should fetch the latest code from the scm and run the build script" do
      mock_scm.should_receive(:with_latest_code).and_yield do
        @builder.should_receive(:run_build_script)
      end
      @builder.build
    end

    it 'should checkout the given commit from the scm and run the build script' do
      mock_scm.should_receive(:with_revision).
        with('6437fa27779daba40dbd130e2937d36253be1d4c').and_yield do
          @builder.should_receive(:run_build_script)
        end
      @builder.build('6437fa27779daba40dbd130e2937d36253be1d4c')
    end
    
    it "should assign the head of the SCM as the commit in the build" do
      mock_build.should_receive(:commit=).with mock_scm.head
      @builder.build
    end
    
    it "should save the build to the database" do
      mock_build.should_receive(:save)
      @builder.build
    end
    
    it "should save the build even if there's an exception" do
      lambda {
        mock_scm.should_receive(:with_latest_code).and_raise(RuntimeError)
        mock_build.should_receive(:save)
        @builder.build
      }.should raise_error(RuntimeError)
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
      @builder.stub!(:successful_execution?).and_return(true)
      mock_build.should_receive(:successful=).with(true)
      @builder.run_build_script
    end
    
    it "should set the build status to 'failed' if the command fails" do
      @builder.stub!(:successful_execution?).and_return(false)
      mock_build.should_receive(:successful=).with(false)
      @builder.run_build_script
    end
  end
  
  describe "When deleting the code for a project" do
    it "should remove the directory from disk" do
      FileUtils.should_receive(:rm_r).with("/var/integrity/exports/foca-integrity")
      @builder.delete_code
    end
    
    it "should not complain if the directory isn't there (e.g, a project with no builds)" do
      FileUtils.stub!(:rm_r).and_raise(Errno::ENOENT)
      lambda { @builder.delete_code }.should_not raise_error
    end
  end
end
