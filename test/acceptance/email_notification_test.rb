require "helper/acceptance"
require "rumbster"
require "message_observers"

class EmailNotificationTest < Test::Unit::AcceptanceTestCase
  story <<-EOS
    As an administrator,
    I want to setup the email notifiers on my projects
    So that I get alerts with every build
  EOS

  setup do
    load "integrity/notifier/email.rb"
  end

  scenario "Sending the notification via SMTP" do
    Net::SMTP.disable_tls
    port     = 10_000 + rand(10)
    server   = Rumbster.new(port)
    observer = MailMessageObserver.new
    server.add_observer(observer)
    server.start

    repo    = git_repo(:my_test_project)
    project = Project.gen(:my_test_project, :uri => repo.uri)
    repo.add_successful_commit

    login_as "admin", "test"
    visit "/my-test-project"
    click_link "Edit Project"

    check "enabled_notifiers_email"
    fill_in "email_notifier_host", :with => "127.0.0.1"
    fill_in "email_notifier_port", :with => port
    fill_in "email_notifier_to",   :with => "hacker@example.org"
    fill_in "email_notifier_from", :with => "ci@example.org"
    select  "cram_md5",            :from => "Auth type"

    click_button "Update"
    click_button "Manual Build"

    mail = observer.messages.first

    assert_equal ["hacker@example.org"], mail.destinations
    assert_equal ["ci@example.org"],  mail.from
    assert mail.subject.include?("successful")

    assert_equal "cram_md5", Sinatra::Mailer.config[:auth]
    server.stop

    visit "/my-test-project"
    click_link "Edit Project"
    assert_have_tag("select#email_notifier_auth option[@value='cram_md5'][@selected='selected']")
  end

  scenario "Sending the notification via sendmail" do
    stub.instance_of(Integrity::Notifier::Email).deliver! { nil }
    repo    = git_repo(:my_test_project)
    project = Project.gen(:my_test_project, :uri => repo.uri)
    repo.add_successful_commit

    login_as "admin", "test"
    visit "/my-test-project"
    click_link "Edit Project"

    check "enabled_notifiers_email"
    fill_in "email_notifier_to",   :with => "hacker@example.org"
    fill_in "email_notifier_from", :with => "ci@example.org"
    fill_in "email_notifier_sendmail", :with => "/usr/local/bin/sendmail"
    click_button "Update"
    click_button "Manual Build"

    assert_equal :sendmail, Sinatra::Mailer.delivery_method
  end
end
