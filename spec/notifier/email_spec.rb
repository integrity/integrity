require File.dirname(__FILE__) + "/../spec_helper"

describe Integrity::Notifier::Email do
  include NotifierSpecHelper
  
  it_should_behave_like "A notifier"

  def klass
    Integrity::Notifier::Email
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
    it "should have a title" do
      the_form.should have_tag("h2", "Email Notifications")
    end
    
    it "should have a text field for the 'to' email addresses" do
      pending "get the hpricot selector for 'email_notifier[to]' right"
      the_form.should have_tag("label[@for=email_notifier_to]", "Send to")
      the_form.should have_tag("input#email_notifier_to[@name='email_notifier[to]']")
    end
    
    it "should have a text field for the 'from' email address" do
      pending "get the hpricot selector for 'email_notifier[from]' right"
      the_form.should have_tag("label[@for=email_notifier_from]", "Send from")
      the_form.should have_tag("input#email_notifier_from[@name='email_notifier[from]']")
    end
    
    it "should have a subtitle 'SMTP Server Configuration'" do
      the_form.should have_tag("h3", "SMTP Server Configuration")
    end
    
    it "should have two text fields for server host and port together" do
      pending "get the hpricot selector for 'email_notifier[host]' and 'email_notifier[port]' right"
      the_form.should have_tag("label[@for=email_notifier_host]", "Host : Port")
      the_form.should have_tag("input#email_notifier_host[@name='email_notifier[host]']")
      the_form.should have_tag("input#email_notifier_port[@name='email_notifier[port]'")
    end
    
    it "should have a text field for the server user" do
      pending "get the hpricot selector for 'email_notifier[user]' right"
      the_form.should have_tag("label[@for=email_notifier_user]", "User")
      the_form.should have_tag("input#email_notifier_user[@name='email_notifier[user]']")
    end

    it "should have a text field for the server password" do
      pending "get the hpricot selector for 'email_notifier[password]' right"
      the_form.should have_tag("label[@for=email_notifier_password]", "Password")
      the_form.should have_tag("input#email_notifier_password[@name='email_notifier[password]']")
    end

    it "should have a text field for the server auth type ('plain' by default)" do
      pending "get the hpricot selector for 'email_notifier[auth]' right"
      the_form.should have_tag("label[@for=email_notifier_auth]", "Auth type")
      the_form.should have_tag("input#email_notifier_auth[@name='email_notifier[auth]'][@value='plain']")
    end
  end
  
  describe "building the email" do
    def notifier_config
      @config ||= {
        :to => "destination@example.com", 
        :from => "integrity@me.com", 
        :host => "smtp.example.com", 
        :port => "25", 
        :user => "blah", 
        :pass => "blah", 
        :auth => "plain"
      }
    end
    
    before do
      @email = stub("email", :deliver! => true)
      @mailer = Integrity::Notifier::Email.new(mock_build, notifier_config)
      Sinatra::Mailer::Email.stub!(:new).and_return(@email)
    end
    
    it "should be sent to the address specified in the options" do
      @mailer.to.should == "destination@example.com"
    end

    it "should be sent from the address specified in the options" do
      @mailer.from.should == "integrity@me.com"
    end

    it "should have a descriptive subject" do
      @mailer.subject.should == "[Integrity] Integrity build e7e02b: SUCCESS"
    end

    it "should include the full commit identifier along with the status in the body" do
      @mailer.body.should =~ /Build e7e02bc669d07064cdbc7e7508a21a41e040e70d was successful/
    end

    describe "the body" do
      it "should include the commit message" do
        @mailer.body.should =~ /Commit Message: the commit message/
      end

      it "should include the commit date" do
        @mailer.body.should =~ /Commit Date: Fri Jul 25 18:44:00 [+|-]\d\d\d\d 2008/
      end

      it "should include the commit author" do
        @mailer.body.should =~ /Commit Author: Nicolás Sanguinetti/
      end

      it "should include the build output" do
        @mailer.body.should =~ /the output/
      end
    end

    it "should create an email with all the information" do
      Sinatra::Mailer::Email.should_receive(:new).with(
        :to => @mailer.to,
        :from => @mailer.from,
        :subject => @mailer.subject,
        :text => @mailer.body
      ).and_return(@email)
      @mailer.email
    end

    it "should deliver the email when it receives the #deliver! message" do
      @email.should_receive(:deliver!)
      @mailer.deliver!
    end
  end
end
