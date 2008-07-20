require File.dirname(__FILE__) + '/spec_helper'

describe Integrity::Build do
  before(:each) do
    @build = Integrity::Build.new
  end

  it 'should not be valid' do
    @build.should_not be_valid
  end

  it "needs an output, a status, and a commit" do
    @build.attributes = {
      :commit => {
        :author => 'Simon Rozet <simon@rozet.name>',
        :identifier => '712041aa093e4fb0a2cb1886db49d88d78605396',
        :message    => 'started build model'
      },
      :output => 'foo',
      :successful => true
    }
    @build.should be_valid
  end

  it 'should have output' do
    @build.output = 'foo'
    @build.output.should == 'foo'
  end

  it 'should have a status' do
    @build.successful = true
    @build.should be_successful
  end

  it 'should default to failure' do
    @build.should be_failed
    @build.should_not be_successful
  end

  it 'should have a commit' do
    @build.commit = {
      :author => 'Simon Rozet <simon@rozet.name>',
      :identifier => '712041aa093e4fb0a2cb1886db49d88d78605396',
      :message    => 'started build model'
    }
    @build.commit[:author].should == 'Simon Rozet <simon@rozet.name>'
  end

  it 'output should default to ""' do
    @build.output.should == ''
  end

  it '#human_readable_status should return "Build successful" or "Build Failed"' do
    @build.stub!(:successful?).and_return(true)
    @build.human_readable_status.should == 'Build Successful'
    @build.stub!(:successful?).and_return(false)
    @build.human_readable_status.should == 'Build Failed'
  end
  
  it "should return the status as a symbol (for html classes or the like)" do
    @build.stub!(:successful?).and_return(true)
    @build.status.should == :success
    @build.stub!(:successful?).and_return(false)
    @build.status.should == :failed
  end
end
