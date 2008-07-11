require  File.dirname(__FILE__) + '/spec_helper'

describe Integrity::Builder do
  before(:each) do
    Integrity.stub!(:scm_export_directory).and_return('/var/integrity/exports')
  end

  describe 'When initializing' do
    it "should creates a new SCM object using the scheme of the given URI's and given options" do
      Integrity::SCM.should_receive(:new).with('git', :branch => 'production')
      Integrity::Builder.new('git://github.com/foca/integrity.git', :scm => {:branch => 'production'})
    end
  end

  describe 'When building the project' do
    before(:each) do
      @scm = mock('SCM', :checkout => true)
      Integrity::SCM.stub!(:new).and_return(@scm)
      @builder = Integrity::Builder.new('git://github.com/foca/integrity.git')
    end

    it 'should tell the scm to checkout the project into the correct directory' do
      @scm.should_receive(:checkout).with('/var/integrity/exports/foca-integrity')
      @builder.build
    end
  end
end
