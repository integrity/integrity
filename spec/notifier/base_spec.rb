require File.dirname(__FILE__) + "/../spec_helper"

describe Integrity::Notifier::Base do
  include AppSpecHelper
  include NotifierSpecHelper

  it_should_behave_like "A notifier"
  
  def klass
    Integrity::Notifier::Base
  end

  it "should raise on #deliver!" do
    notifier = klass.new(mock_build, {})
    lambda { notifier.deliver! }.should raise_error(NoMethodError, /you need to implement this method in your notifier/)
  end
  
  describe "notifying the world of a build" do
    before { klass.stub!(:new).and_return(notifier) }
    
    it "should instantiate a notifier with the given build and config" do
      klass.should_receive(:new).with(mock_build, {}).and_return(notifier)
      klass.notify_of_build(mock_build, notifier_config)
    end
  
    it "should pass the notifier options to the notifier" do
      klass.should_receive(:new).with(anything, notifier_config).and_return(notifier)
      klass.notify_of_build(mock_build, notifier_config)
    end
    
    it "should deliver the notification" do
      notifier.should_receive(:deliver!)
      klass.notify_of_build(mock_build, notifier_config)
    end
  end
  
  describe "generating the config form" do
    it "should return the path to the file" do
      File.stub!(:read).with("#{Integrity.root}/lib/integrity/notifier/base.haml").and_return("haml file")
      klass.to_haml.should == "haml file"
    end
  end
  
  describe "getting the build message" do
    before { @notifier = klass.new(mock_build, {}) }
    
    it "should have a nice short_message when the build was successful" do
      mock_build.stub!(:successful?).and_return(true)
      @notifier.short_message.should == "Build e7e02b was successful"
    end
    
    it "should have a nice short_message when the build wasn't successful" do
      mock_build.stub!(:successful?).and_return(false)
      @notifier.short_message.should == "Build e7e02b failed"
    end
    
    it "should show the build status on the full_message" do
      mock_build.stub!(:successful?).and_return(true)
      @notifier.full_message.should =~ /Build e7e02bc669d07064cdbc7e7508a21a41e040e70d was successful/
    end
    
    it "should show the commit message on the full_message" do
      @notifier.full_message.should =~ /Commit Message: the commit message/
    end
    
    it "should show the commit date on the full_message" do
      @notifier.full_message.should =~ /Commit Date: Fri Jul 25 18:44:00 [+|-]{1}\d{4} 2008/
    end

    it "should show the commit author on the full_message" do
      @notifier.full_message.should =~ /Commit Author: Nicolás Sanguinetti/
    end
    
    it "should show a link back to the integrity build page on the full_message" do
      @notifier.full_message.should =~ %r(Link: http://localhost:4567/integrity/builds/e7e02bc669d07064cdbc7e7508a21a41e040e70d)
    end
    
    it "should show the stripped build output on the full_message" do
      @notifier.full_message.should =~ /Build Output:\n\nthe output with color coding/
    end
  end
end
