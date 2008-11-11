require File.dirname(__FILE__) + "/../spec_helper"

describe Integrity::Notifier::Jabber do
  include AppSpecHelper
  include NotifierSpecHelper
  
  it_should_behave_like "A notifier"
  
  def klass
    Integrity::Notifier::Jabber
  end
  
  describe "notifying the world of a build" do
    before { klass.stub!(:new).and_return(notifier) }
    
    it "should instantiate a notifier with the given build and config" do
      klass.should_receive(:new).with(mock_build, anything).and_return(notifier)
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
  
  describe "generating a form for configuration" do
    describe "with a field for the recipients" do
      it "should have the proper name, id and label" do
        the_form.should have_textfield("jabber_notifier_recipients").named("notifiers[Jabber][recipients]").with_label("Recipients").with_value(nil)
      end
      
      it "should use the config's 'to' value if available" do
        the_form(:config => { 'recipients' => 'test@example.com' }).should have_textfield("jabber_notifier_recipients").with_value("test@example.com")
      end
    end
    
    it "should have a subtitle 'Jabber Server Configuration'" do
      the_form.should have_tag("h3", "Jabber Server Configuration")
    end
    
    describe "with a field for the user" do
      it "should have the proper name, id and label" do
        the_form.should have_textfield("jabber_notifier_user").named("notifiers[Jabber][user]").with_label("User").with_value(nil)
      end

      it "should use the config's 'to' value if available" do
        the_form(:config => { 'user' => 'test@morejabber.com' }).should have_textfield("jabber_notifier_user").with_value("test@morejabber.com")
      end
    end

    describe "with a field for the pass" do
      it "should have the proper name, id and label" do
        the_form.should have_textfield("jabber_notifier_pass").named("notifiers[Jabber][pass]").with_label("Pass").with_value(nil)
      end

      it "should use the config's 'to' value if available" do
        the_form(:config => { 'pass' => '42' }).should have_textfield("jabber_notifier_pass").with_value("42")
      end
    end
  end
  
  describe 'when sending a notify with jabber' do
    it 'should send a message to each recipients' do
      @jabber_client = mock('jabber')
      Jabber::Simple.stub!(:new).and_return(@jabber_client)
      @jabber_notifier = Integrity::Notifier::Jabber.new(mock_build, notifier_config)
      @jabber_notifier.recipients.each { |r| @jabber_client.stub!(:deliver).with(r, anything).and_return(true) }
      @jabber_notifier.deliver!
    end
  end
  
  describe 'building a message' do
    before do
       Jabber::Simple.stub!(:new).and_return(mock('jabber'))
       @jabber_notifier = Integrity::Notifier::Jabber.new(mock_build, notifier_config) 
    end

    it 'should prepare a list of recipients' do
     @jabber_notifier.recipients.should == ['ph@hey-ninja.com', 'more@foom.com']
    end

    describe 'the content of the message' do
     it "should include the commit message" do
       @jabber_notifier.message.should =~ /Commit Message: 'the commit message'/
     end

     it "should include the commit date" do
       @jabber_notifier.message.should =~ /at Fri Jul 25 18:44:00 [+|-]\d\d\d\d 2008/
     end

     it "should include the commit author" do
       @jabber_notifier.message.should =~ /by Nicolás Sanguinetti/
     end

     it "should include the link to the integrity build" do
       @jabber_notifier.message.should =~ /\/integrity\/builds\/e7e02bc669d07064cdbc7e7508a21a41e040e70d/
     end
    end
  end
  
  def notifier_config
    @configs ||= { :recipients => 'ph@hey-ninja.com more@foom.com' }
  end
end
