require File.dirname(__FILE__) + '/../spec_helper'
require File.dirname(__FILE__) + '/../../lib/integrity/scm/git'

describe Integrity::SCM::Git do
  before(:each) do
    @uri = Addressable::URI.parse('git://github.com/foca/integrity.git')
    @build = mock('build model',
      :output => '',
      :error  => '',
      :status => true
    )
    @scm = Integrity::SCM::Git.new(@uri, 'master', @build)
  end

  describe 'When checking-out a repository' do
    before(:each) do
      Open3.stub!(:popen3)
      @stdout = mock('io', :read => 'out')
      @stderr = mock('io', :read => 'err')
      $?.stub!(:success?).and_return(true)
    end

    it 'should do a shallow clone of the repository into the given directory' do
      Open3.should_receive(:popen3).
        with('git clone --depth 1 git://github.com/foca/integrity.git /foo/bar')
      @scm.checkout('/foo/bar')
    end

    it 'should switch to the specified branch' do
      Open3.should_receive(:popen3).
        with('git --git-dir=/foo/bar/.git checkout master')
      @scm.checkout('/foo/bar')
    end

    it 'should fetch updates' do
      Open3.should_receive(:popen3).with('git --git-dir=/foo/bar/.git pull')
      @scm.checkout('/foo/bar')
    end

    it 'should return false if one of the command failed' do
      @scm.stub!(:execute).and_raise(RuntimeError)
      @scm.checkout('/foo/bar').should be_false
    end

    it "should write stdout to build's output" do
      Open3.stub!(:popen3).and_yield('', @stdout, @stderr)
      @build.output.should_receive(:<<).with('out').exactly(3).times
      @scm.checkout('/foo/bar')
    end

    it "should write stderr to build's error" do
      Open3.stub!(:popen3).and_yield('', @stdout, @stderr)
      @build.error.should_receive(:<<).with('err').exactly(3).times
      @scm.checkout('/foo/bar')
    end
  end
end
