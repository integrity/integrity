require "helper/acceptance"

class IRCNotificationTest < Test::Unit::AcceptanceTestCase

  story <<-EOS
    As an administrator,
    I want to setup the IRC notifiers on my projects
    So that I get alerts with every build
  EOS

  setup do
    load "integrity/notifier/irc.rb"
  end

  teardown do
    Notifier.available.replace({})
  end

  scenario "Sending the notification via IRC" do
    irc = "irc://test@irc.freenode.net:6667/#test"
    repo = git_repo(:my_test_project)
    Project.gen(:my_test_project, :uri => repo.uri)
    repo.add_successful_commit

    login_as "admin", "test"
    visit "/my-test-project"
    click_link "Edit"

    check "enabled_notifiers_irc"
    fill_in "irc_notifier_uri", :with => irc

    mock(ShoutBot).shout(irc) { nil }

    click_button "Update"
    click_button "Manual Build"

    visit "/my-test-project"
    click_link "Edit"
  end

end
