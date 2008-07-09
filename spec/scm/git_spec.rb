require File.dirname(__FILE__) + '/../spec_helper'
require File.dirname(__FILE__) + '/../../lib/integrity/scm/git'

describe Integrity::SCM::Git do
  before(:each) do
    Integrity.stub!(:scm_export_directory).and_return('/foo/bar')
    @git = mock('grit', :clone => true, :checkout => true, :git_dir => '/foo/bar/foca-integrity')
    Grit::Git.stub!(:new).and_return(@git)
    @scm = Integrity::SCM::Git.new('git://github.com/foca/integrity.git')
  end

  it 'should initialize Grit with correct git-dir' do
    Grit::Git.should_receive(:new).with('/foo/bar/foca-integrity')
    Integrity::SCM::Git.new('git://github.com/foca/integrity.git')
  end

  it 'should default branch to master' do
    @scm.branch.should == 'master'
  end

  describe 'When checking-out a repository' do
    it 'should do a shallow clone of the repository into the git-dir specified earlier' do
      @git.should_receive(:clone).with({:depth => 1},
        'git://github.com/foca/integrity.git', '/foo/bar/foca-integrity')
      @scm.checkout
    end

    it 'should switch to the specified branch' do
      @git.should_receive(:checkout).with('master')
      @scm.checkout
    end
  end
end
