require File.dirname(__FILE__) + '/../spec_helper'
require File.dirname(__FILE__) + '/../../lib/integrity/scm/git'

describe Integrity::SCM::Git do
  before(:each) do
    @uri = Addressable::URI.parse('git://github.com/foca/integrity.git')
    @build = mock('build model', :error => '', :output => '', :status => true)
    @scm = Integrity::SCM::Git.new(@uri, 'master', @build)
  end

  describe 'When checking-out a repository' do
    before(:each) do
      Open3.stub!(:popen3)
    end

    it 'should do a shallow clone of the repository into the given directory' do
      pending
      Open3.should_receive(:popen3).
        with('git clone --depth 1 git://github.com/foca/integrity.git /foo/bar')
      @scm.checkout('/foo/bar')
    end

    it 'should switch to the specified branch' do
      pending
      Open3.should_receive(:popen3).with(/clone/)
      Open3.should_receive(:popen3).with('git --git-dir=/foo/bar checkout master').once.ordered
      @scm.checkout('/foo/bar')
    end

    it 'should fetch updates' do
      pending
      Open3.stub!(:popen3).with(/clone/)
      Open3.stub!(:popen3).with(/checkout/)
      Open3.should_receive(:popen3).with { |a| a.should == 'git --git-dir=/foo/bar pull' }
      @scm.checkout('/foo/bar')
    end

    it 'should return false if one of the command failed' do
      @scm.stub!(:execute).and_raise(RuntimeError)
      @scm.checkout('/foo/bar').should be_false
    end

    it "should write stdout to build's output" do
      Open3.stub!(:popen3).and_yield('', 'foo', '')
      @build.output.should_receive(:<<).with('foo')
      @scm.checkout('/foo/bar')
    end

    it "should write stderr to build's error" do
      Open3.stub!(:popen3).and_yield('', '', 'err')
      @build.error.should_receive(:<<).with('err')
      @scm.checkout('/foo/bar')
    end
  end
end
