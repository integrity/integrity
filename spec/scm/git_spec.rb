require File.dirname(__FILE__) + '/../spec_helper'
require File.dirname(__FILE__) + '/../../lib/integrity/scm/git'

describe Integrity::SCM::Git do
  before(:each) do
    @uri = Addressable::URI.parse('git://github.com/foca/integrity.git')
    @build = mock('build model',
      :output => '',
      :error  => '',
      :status => true,
      :status= => 1
    )
    @scm = Integrity::SCM::Git.new(@uri, 'master', @build)
  end

  describe 'When asking if the repository is already cloned (#cloned?)' do
    it 'should be false if the repository git dir exists' do
      File.should_receive(:directory?).with('foo/.git').and_return(true)
      @scm.send(:cloned?, 'foo').should be_true
    end

    it 'should be false if the repository git dir doesnt exists' do
      File.should_receive(:directory?).with('foo/.git').and_return(false)
      @scm.send(:cloned?, 'foo').should be_false
    end
  end

  describe 'When asking if the repository is already on the right branch' do
    it 'should be true if .git/HEAD does point to the right branch' do
      File.should_receive(:read).with('foo/.git/HEAD').and_return("refs/heads/master\n")
      @scm.send(:on_branch?, 'foo').should be_true
    end

    it 'should be false if .git/HEAD doesnt point to it' do
      File.should_receive(:read).with('foo/.git/HEAD').and_return("refs/heads/blargh\n")
      @scm.send(:on_branch?, 'foo').should be_false
    end
  end

  describe 'When creating the checkout script' do
    before(:each) do
      @scm.stub!(:cloned?).and_return(false)
      @scm.stub!(:on_branch?).and_return(false)
    end

    it 'should return an enumerable' do
      @scm.checkout_script('/foo/bar').should respond_to(:each)
    end

    it "should clone the repository" do
      @scm.checkout_script('/foo/bar').should include("git clone --depth 1 git://github.com/foca/integrity.git /foo/bar")
    end
    
    it "should not try to clone if the repo has already been cloned" do
      @scm.stub!(:cloned?).and_return(true)
      @scm.checkout_script('/foo/bar').should_not include("git clone --depth 1")
    end

    it 'should switch to the specified branch' do
      @scm.checkout_script('/foo/bar').should include("git --git-dir=/foo/bar/.git checkout master")
    end

    it 'should switch not switch of branch if already on it' do
      @scm.stub!(:on_branch?).and_return(true)
      @scm.checkout_script('/foo/bar').should_not include("git --git-dir=/foo/bar/.git checkout master")
    end

    it 'should fetch updates' do
      @scm.checkout_script('/foo/bar').should include("git --git-dir=/foo/bar/.git pull")
    end
  end
end
