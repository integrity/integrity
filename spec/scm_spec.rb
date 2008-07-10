require File.dirname(__FILE__) + '/spec_helper'

describe Integrity::SCM do
  describe 'when loading an SCM adapter' do
    it 'should instantiate the handler with given options' do
      Integrity::SCM::Git.should_receive(:new).with(:branch => 'master')
      Integrity::SCM.new('git', :branch => 'master')
    end

    it "should raise an error if the handler isn't defined into the file" do
      Integrity::SCM.send(:remove_const, :Git)
      lambda do
        Integrity::SCM.new('git')
      end.should raise_error(RuntimeError, "could not find any SCM named `git'")
    end

    it "should raise an error if the file defining the handler can't be loaded" do
      lambda do
        Integrity::SCM.new('git')
      end.should raise_error(RuntimeError, "could not find any SCM named `git'")
    end
  end
end
