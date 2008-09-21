require File.dirname(__FILE__) + "/../spec_helper"

describe Integrity::Notifier::Email do
  def mock_build(messages={})
    messages = {
      :project => stub("project", :name => "Integrity", :permalink => "integrity"),
      :commit_identifier => "e7e02bc669d07064cdbc7e7508a21a41e040e70d",
      :short_commit_identifier => "e7e02b",
      :status => :success,
      :successful? => true,
      :commit_message => "the commit message",
      :commit_author => stub("author", :name => "Nicolás Sanguinetti"),
      :commited_at => Time.mktime(2008, 07, 25, 18, 44),
      :output => "the output"
    }.merge(messages)
    @build ||= stub("build", messages)
  end

  before do
    @email = stub("email", :deliver! => true)
    @mail_notifier = @email
    Integrity.stub!(:config).and_return(:email => {:to => "destination@example.com", :from => "integrity@me.com", :config => {}})
    Sinatra::Mailer::Email.stub!(:new).and_return(@email)
  end

  it "should instantiate a notifier with the given build" do
    Integrity::Notifier::Email.should_receive(:new).with(mock_build, anything).and_return(@mail_notifier)
    Integrity::Notifier::Email.notify_of_build(mock_build)
  end

  it "should pass the global email options to the notifier" do
    options_checker = hash_including(:to => "destination@example.com", :from => "integrity@me.com")
    Integrity::Notifier::Email.should_receive(:new).with(anything, options_checker).and_return(@mail_notifier)
    Integrity::Notifier::Email.notify_of_build(mock_build)
  end

  describe "building an email" do
    before { @mailer = Integrity::Notifier::Email.new(mock_build, Integrity.config[:email]) }

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
