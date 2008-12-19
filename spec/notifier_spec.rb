require File.dirname(__FILE__) + "/spec_helper"

describe Integrity::Notifier do
  include DatabaseSpecHelper
  include NotifierSpecHelper
  
  def valid_attributes(attributes={})
    { :name => "Stub", :config => { :a => 1 } }.merge(attributes)
  end
  
  def sample_notifier(attributes={})
    @notifier ||= sample_project.notifiers.create(valid_attributes(attributes))
  end
  
  def sample_project
    @project ||= Integrity::Project.create(:name => "Blah", :uri => "blah.blah")
  end

  def other_project
    @other_project ||= Integrity::Project.create(:name => "Blah Blah Blah", :uri => "blah.blah")
  end
  
  describe "configuring a notifier" do
    it "should not be valid by default" do
      sample_notifier(:name => nil, :project_id => nil, :config => nil).should_not be_valid
    end
  
    it "should be valid if passed a name, a project and a config hash" do
      sample_notifier.should be_valid
    end
  end
  
  describe "getting the list of existent notifiers" do
    it "should not list the Base notifier" do
      Integrity::Notifier.available.should_not include(Integrity::Notifier::Base)
    end
  end
  
  describe "setting up a list of notifiers for a project" do
    it "should create a notifier per item passed" do
      lambda {
        sample_project.enable_notifiers(["Cuack", "Test"], "Cuack" => { "foo" => "bar"},
                                                           "Test" => { "bar" => "baz "},
                                                           "Unavailable" => { "baz" => "quux" })
      }.should change(Integrity::Notifier, :count).by(2)
    end
    
    it "should do nothing if passing nil as the list of enabled notifiers" do
      lambda {
        sample_project.enable_notifiers(nil, {})
      }.should_not change(Integrity::Notifier, :count)
    end
    
    it "should assume you're passing the notifier name if it's not an array or nil" do
      lambda {
        sample_project.enable_notifiers("Blah", "Blah" => { "foo" => "bar" })
      }.should change(Integrity::Notifier, :count).by(1)
    end

    it "should destroy all of the previous notifiers for that project" do
      sample_project.enable_notifiers("Blah", "Blah" => { "foo" => "bar" })
      sample_project.enable_notifiers(["Cuack", "Test"], "Cuack" => { "foo" => "bar"},
                                                         "Test" => { "bar" => "baz "})

      sample_project.notifiers.length.should == 2
    end

    it "should not destroy all of the other notifiers that exist for other projects" do
      other_project.enable_notifiers("Blah", "Blah" => { "foo" => "bar" })
      sample_project.enable_notifiers("Blah", "Blah" => { "foo" => "bar" })
      other_project.notifiers.length.should == 1
    end
  end
  
  describe "Notifying the world of a build" do    
    it "should delegate to the notifier class" do
      build = mock("build")
      Integrity::Notifier::Stub.should_receive(:notify_of_build).with(build, sample_notifier.config)
      sample_notifier.notify_of_build(build)
    end
  end
end
