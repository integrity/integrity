require  File.dirname(__FILE__) + '/spec_helper'

describe Integrity::Builder, 'When initializing' do
  before(:each) do
    Integrity::Build.stub!(:new).and_return(@build)
    Integrity::SCM.stub!(:new)
  end

  it 'should instantiate a new Build model' do
    Integrity::Build.should_receive(:new).and_return(@build)
    Integrity::Builder.new(@uri, 'foo', 'bar')
  end

  it "should creates a new SCM object using the given URI's and given options and pass it the build" do
    Integrity::SCM.should_receive(:new).with(@uri, 'production', @build)
    Integrity::Builder.new(@uri, 'production', 'rake')
  end
end

describe Integrity::Builder do
  before(:each) { Integrity::Builder.class_eval { public  :build_script, :execute, :export_directory } }
  after(:each)  { Integrity::Builder.class_eval { private :build_script, :execute, :export_directory } }

  before(:each) do
    Integrity.stub!(:config).and_return(:export_directory => '/var/integrity/exports')
    @uri = Addressable::URI.parse('git://github.com/foca/integrity.git')
    @build = mock('build model', :output => '', :error => '', :status= => 1, :failure? => false, :execute => nil)
    @scm = mock('SCM', :checkout_script => ["clone", "checkout", "pull"])
    Integrity::SCM.stub!(:new).and_return(@scm)
    Integrity::Build.stub!(:new).and_return(@build)
    @builder = Integrity::Builder.new(@uri, 'master', 'rake')
  end

  describe "Calculating the export directory" do
    it "should start with the base export directory set in the global options" do
      @builder.export_directory.should =~ %r(^/var/integrity/exports)
    end
    
    it "should use the path to the repo in this directory, changing slashes for hyphens" do
      @builder.export_directory.should =~ %r(foca-integrity$)
    end
  end

  describe "When creating the build script" do
    before(:each) do
      @builder.stub!(:export_directory).and_return('/var/integrity/exports/foca-integrity')
    end
    
    it "should return an enumerable" do
      @builder.build_script.should respond_to(:each)
    end
    
    it "should contain the scm build script" do
      @builder.build_script.should include(*@scm.checkout_script)
    end
    
    it "should cd into the export directory" do
      @builder.build_script.should include("cd /var/integrity/exports/foca-integrity")
    end
    
    it "should include the project build command" do
      @builder.build_script.should include("rake")
    end
  end

  describe 'When building a project' do
    before(:each) do
      @builder.stub!(:execute).and_return(true)
      @builder.stub!(:build_script).and_return(["clone", "checkout", "pull", "cd", "rake"])
      @builder.stub!(:successful_execution?).and_return(true)
    end
    
    it "should run all the commands in the build script" do
      @builder.should_receive(:execute).exactly(5).times
      @builder.build
    end
    
    it "should stop as soon as one command fails" do
      @builder.stub!(:successful_execution?).and_return(true, true, false)
      @builder.should_receive(:execute).exactly(3).times
      @builder.build
    end
    
    it "should return the build" do
      @builder.build.should == @build
    end
    
    it "should return the build if it fails" do
      @builder.stub!(:successful_execution?).and_return(false)
      @builder.build.should == @build
    end
  end
  
  describe 'When running the command' do
    before(:each) do
      @stdout = mock('out', :read => 'out')
      @stderr = mock('out', :read => 'err')
      Open3.stub!(:popen3).and_yield('', @stdout, @stderr)
      $?.stub!(:success?).and_return(true)
    end
    
    it "should execute it" do
      Open3.should_receive(:popen3).with("blah")
      @builder.execute("blah")
    end
    
    it "should write stdout to build's output" do
      @build.output.should_receive(:<<).with('out')
      @builder.execute("blah")
    end
  
    it "should write stderr to build's error" do
      @build.error.should_receive(:<<).with('err')
      @builder.execute("blah")
    end
    
    it "should set build's status to success" do
      @builder.stub!(:successful_execution?).and_return(true)
      @build.should_receive(:status=).with(true)
      @builder.execute("blah")
    end

    it "should set build's status to failure" do
      @builder.stub!(:successful_execution?).and_return(false)
      @build.should_receive(:status=).with(false)
      @builder.execute("blah")
    end
  end
end
