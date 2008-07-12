require  File.dirname(__FILE__) + '/spec_helper'

describe Integrity::Builder do
  before(:each) do
    @uri = Addressable::URI.parse('git://github.com/foca/integrity.git')
    @build = mock('build model', :output => '', :error => '', :status= => 1, :failure? => false)
    Integrity.stub!(:config).and_return(:export_directory => '/var/integrity/exports')
  end

  describe 'When initializing' do
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

  describe 'When building a project' do
    before(:each) do
      @scm = mock('SCM', :checkout => true)
      Integrity::SCM.stub!(:new).and_return(@scm)
      Integrity::Build.stub!(:new).and_return(@build)
      @builder = Integrity::Builder.new(@uri, 'master', 'rake')
      Kernel.stub!(:system)
      @builder.stub!(:run_command)
    end

    it 'should tell the scm to checkout the project into the export directory' do
      @scm.should_receive(:checkout).with('/var/integrity/exports/foca-integrity').
        and_return(@result)
      @builder.build
    end

    it "should stop furter processing and return false if repository's checkout failed" do
      @build.stub!(:failure?).and_return(true)
      @builder.build.should be_false
    end

    it 'should return the build' do
      @builder.build.should == @build
    end

    describe 'When running the command' do
      before(:each) do
        @builder = Integrity::Builder.new(@uri, 'master', 'echo rake')
        @stdout = mock('out', :read => 'out')
        @stderr = mock('out', :read => 'err')
        @builder.stub!(:export_directory).and_return(File.dirname(__FILE__))
        $?.stub!(:success?).and_return(true)
      end

      it 'should change directory to where the repository was checked out' do
        Open3.stub!(:popen3)
        @builder.stub!(:export_directory).and_return('/var/integrity/exports/foca-integrity')
        Dir.should_receive(:chdir).with('/var/integrity/exports/foca-integrity')
        @builder.build
      end

      it 'should run the command' do
        Open3.should_receive(:popen3).with('echo rake')
        @builder.build
      end

      it "should write stdout to build's output" do
        Open3.stub!(:popen3).and_yield('', @stdout, @stderr)
        @build.output.should_receive(:<<).with('out')
        @builder.build
      end

      it "should write stderr to build's error" do
        Open3.stub!(:popen3).and_yield('', @stdout, @stderr)
        @build.error.should_receive(:<<).with('err')
        @builder.build
      end

      it "should set build's status to success" do
        @builder.stub!(:successful_command?).and_return(true)
        @build.should_receive(:status=).with(true)
        @builder.build
      end

      it "should set build's status to failure" do
        @builder.stub!(:successful_command?).and_return(false)
        @build.should_receive(:status=).with(false)
        @builder.build
      end
    end
  end
end
