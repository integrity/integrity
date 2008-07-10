require File.dirname(__FILE__) + '/spec_helper'

describe Integrity::Build do
  before(:each) do
    @build = Integrity::Build.new
  end

  it 'should not be valid' do
    @build.should_not be_valid
  end

  it "needs an output, result, and a commit" do
    @build.attributes = {
      :commit => {
        :author => 'Simon Rozet <simon@rozet.name>',
        :identifier => '712041aa093e4fb0a2cb1886db49d88d78605396',
        :message    => 'started build model'
      },
      :output => 'foo',
      :result => true
    }
    @build.should be_valid
  end

  it 'should have output' do
    @build.output = 'foo'
    @build.output.should == 'foo'
  end

  it 'should have error' do
    @build.error = 'err!'
    @build.error.should == 'err!'
  end

  it 'should have a result' do
    @build.result = true
    @build.should be_success
  end

  it 'should default to failure' do
    @build.should be_failure
    @build.should_not be_success
  end

  it 'should have a commit' do
    @build.commit = {
      :author => 'Simon Rozet <simon@rozet.name>',
      :identifier => '712041aa093e4fb0a2cb1886db49d88d78605396',
      :message    => 'started build model'
    }
    @build.commit[:author].should == 'Simon Rozet <simon@rozet.name>'
  end
end
