require  File.dirname(__FILE__) + '/spec_helper'

describe Integrity::Builder do
  describe 'When initializing' do
    it "should creates a new SCM object using the scheme of the given URI's and given options" do
      Integrity::SCM.should_receive(:new).with('git', :branch => 'production')
      Integrity::Builder.new('git://github.com/foca/integrity.git', :scm => {:branch => 'production'})
    end
  end
end
