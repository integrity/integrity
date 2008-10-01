require File.dirname(__FILE__) + "/spec_helper"

describe Integrity::Notifier do
  def valid_attributes(attributes={})
    { :name => "Email",
      :project_id => 1,
      :config => { :to => "to@example.com", :from => "from@example.com",
                   :host => "smtp.example.com" } 
      }.merge(attributes)
  end
  
  def sample_notifier(attributes={})
    @notifier ||= Integrity::Notifier.new valid_attributes(attributes)
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
    #Integrity::Notifier.stub!(:constants).and_return []
  end
end