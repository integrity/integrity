require File.dirname(__FILE__) + '/spec_helper'

describe Integrity::SCM do
  describe 'when loading an SCM adapter' do
    before(:each) do
      module Integrity; module SCM; class Git
        def initialize(*args); end
      end; end; end
      Kernel.stub!(:require).and_return(true)
    end

    it 'should require the file' do
      Kernel.should_receive(:require).with(/scm\/git/)
      Integrity::SCM.new('git')
    end

    it 'should instantiate the handler with given options' do
      Integrity::SCM::Git.should_receive(:new).with(:branch => 'master')
      Integrity::SCM.new('git', :branch => 'master')
    end

    it "should raise an error if the handler isn't defined into the file" do
      Integrity::SCM.send(:remove_const, :Git)
      lambda do
        Integrity::SCM.new('git')
      end.should raise_error(RuntimeError, "could not find `Integrity::SCM::Git' in `scm/git'")
    end

    it "should raise an error if the file defining the handler can't be loaded" do
      Kernel.stub!(:require).and_raise(LoadError)
      lambda do
        Integrity::SCM.new('git')
      end.should raise_error(RuntimeError, "could not find any SCM named `git'")
    end
  end
end
