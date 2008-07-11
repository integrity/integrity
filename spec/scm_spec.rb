require File.dirname(__FILE__) + '/spec_helper'

describe Integrity::SCM do
  describe 'when loading an SCM adapter' do
    before(:each) do
      @uri = Addressable::URI.parse('git://github.com/foca/integrity.git')
    end

    it 'should instantiate the adapter with the given options' do
      build = mock('build model')
      Integrity::SCM::Git.should_receive(:new).
        with(@uri, 'master', build)
      Integrity::SCM.new(@uri, 'master', build)
    end

    it "should raise an error if the handler isn't defined into the file" do
      Integrity::SCM.send(:remove_const, :Git)
      lambda do
        Integrity::SCM.new(@uri)
      end.should raise_error(RuntimeError, "could not find any SCM named `git'")
    end

    it "should raise an error if the file defining the handler can't be loaded" do
      lambda do
        Integrity::SCM.new(@uri)
      end.should raise_error(RuntimeError, "could not find any SCM named `git'")
    end
  end
end
