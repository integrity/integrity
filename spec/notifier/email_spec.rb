require File.dirname(__FILE__) + "/../spec_helper"

describe Integrity::Notifier::Email do
  include AppSpecHelper
  include NotifierSpecHelper
  
  it_should_behave_like "A notifier"

  def klass
    Integrity::Notifier::Email
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
  
  describe "generating a form for configuration" do
    describe "with a field for the destination email address" do
      it "should have the proper name, id and label" do
        the_form.should have_textfield("email_notifier_to").named("notifiers[Email][to]").with_label("Send to").with_value(nil)
      end
      
      it "should use the config's 'to' value if available" do
        the_form(:config => { 'to' => 'test@example.com' }).should have_textfield("email_notifier_to").with_value("test@example.com")
      end
    end

    describe "with a field for the sender email address" do
      it "should have the proper name, id and label" do
        the_form.should have_textfield("email_notifier_from").named("notifiers[Email][from]").with_label("Send from").with_value(nil)
      end
      
      it "should use the config's 'from' value if available" do
        the_form(:config => { 'from' => 'test@example.com' }).should have_textfield("email_notifier_from").with_value("test@example.com")
      end
    end
        
    it "should have a subtitle 'SMTP Server Configuration'" do
      the_form.should have_tag("h3", "SMTP Server Configuration")
    end
    
    describe "with the fields for the smtp host and port" do
      it "should have the proper data for the 'host' field" do
        the_form.should have_textfield("email_notifier_host").named("notifiers[Email][host]").with_label("Host : Port").with_value(nil)
      end
      
      it "should have the proper data for the 'port' field" do
        the_form.should have_textfield("email_notifier_port").named("notifiers[Email][port]").without_label.with_value(nil)
      end
      
      it "should use the config's 'host' value if available" do
        the_form(:config => { 'host' => 'smtp.example.com' }).should have_textfield("email_notifier_host").with_value("smtp.example.com")
      end

      it "should use the config's 'port' value if available" do
        the_form(:config => { 'port' => '25' }).should have_textfield("email_notifier_port").without_label.with_value("25")
      end
    end
    
    describe "with the field for the smtp user" do
      it "should have the proper name, id and label" do
        the_form.should have_textfield("email_notifier_user").named("notifiers[Email][user]").with_label("User").with_value(nil)
      end
      
      it "should use the config's 'user' value if available" do
        the_form(:config => { 'user' => 'auser' }).should have_textfield("email_notifier_user").with_value("auser")
      end
    end

    describe "with the field for the smtp password" do
      it "should have the proper name, id and label" do
        the_form.should have_textfield("email_notifier_pass").named("notifiers[Email][pass]").with_label("Password").with_value(nil)
      end
      
      it "should use the config's 'pass' value if available" do
        the_form(:config => { 'pass' => '****' }).should have_textfield("email_notifier_pass").with_value("****")
      end
    end

    describe "with the field for the smtp auth type" do
      it "should have the proper name, id and label" do
        the_form.should have_textfield("email_notifier_auth").named("notifiers[Email][auth]").with_label("Auth type").with_value("plain")
      end
      
      it "should use the config's 'auth' value if available" do
        the_form(:config => { 'auth' => 'login' }).should have_textfield("email_notifier_auth").with_value("login")
      end
    end
  end
  
  describe "building the email" do
    def notifier_config
      @config ||= {
        "to" => "destination@example.com", 
        "from" => "integrity@me.com", 
        "host" => "smtp.example.com", 
        "port" => "25", 
        "user" => "blah", 
        "pass" => "blah", 
        "auth" => "plain"
      }
    end
    
    before do
      @email = stub("email", :deliver! => true)
      @mailer = Integrity::Notifier::Email.new(mock_build, notifier_config)
      Integrity.stub!(:config).and_return(:base_url => 'http://integrityapp.com:7654')
      Sinatra::Mailer::Email.stub!(:new).and_return(@email)
    end
    
    it "should be sent to the address specified in the options" do
      @mailer.to.should == "destination@example.com"
    end

    it "should be sent from the address specified in the options" do
      @mailer.from.should == "integrity@me.com"
    end

    it "should have a descriptive subject" do
      @mailer.subject.should == "[Integrity] Integrity: Build e7e02b was successful"
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

      it "should link to the build using the base URL configured in the options" do
        @mailer.body.should =~ %r|http://integrityapp\.com:7654/integrity/builds/e7e02b|
      end
      
      it "should include the build output" do
        @mailer.body.should =~ /the output/
      end

      it "should strip ANSI color codes from the build output" do
        @mailer.body.should_not =~ /\e\[31m/
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
