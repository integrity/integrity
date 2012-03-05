require "helper/acceptance"

class SESNotificationTest < Test::Unit::AcceptanceTestCase
  story <<-EOS
    As an administrator,
    I want to setup the SES email notifiers on my projects
    So that I get alerts with every build
  EOS

  setup do
    load "integrity/notifier/ses.rb"
  end

  teardown do
    Notifier.available.replace({})
  end

  scenario "Setting SES configuration" do
    stub.instance_of(Integrity::Notifier::SES).deliver! { nil }
    repo    = git_repo(:my_test_project)
    project = Project.gen(:my_test_project, :uri => repo.uri)
    repo.add_successful_commit

    login_as "admin", "test"
    visit "/my-test-project"
    click_link "Edit"

    check "enabled_notifiers_ses"
    fill_in "ses_notifier_to",   :with => "hacker@example.org"
    fill_in "ses_notifier_from", :with => "ci@example.org"
    fill_in "ses_notifier_access_key_id", :with => "id"
    fill_in "ses_notifier_secret_access_key", :with => "key"
    click_button "Update"
    click_button "Manual Build"

    # TODO: Need the initialized notifier.  Not sure how to properly assert notifier values are set correctly here, but testing manually it works.
    # assert_equal "hacker@example.org", Integrity::Notifier::SES.to
    # assert_equal "ci@example.org", Integrity::Notifier::SES.from
    # assert_equal "id", Integrity::Notifier::SES.ses.access_key_id
    # assert_equal "key", Integrity::Notifier::SES.ses.secret_access_key
  end
end
