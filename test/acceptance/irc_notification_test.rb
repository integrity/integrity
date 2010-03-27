require "helper/acceptance"

class IRCNotificationTest < Test::Unit::AcceptanceTestCase
  story <<-EOS
    As an administrator,
    I want to setup the IRC notifiers on my projects
    So that I get alerts with every build
  EOS

  setup do
    load "integrity/notifier/irc.rb"
    @server = mock_socket
  end

  def build(status)
    repo = git_repo(:my_test_project)
    status.zero? ? repo.add_successful_commit : repo.add_failing_commit
    Project.gen(:my_test_project, :uri => repo.uri)

    login_as "admin", "test"
    visit "/my-test-project"
    click_link "Edit Project"

    check "enabled_notifiers_irc"
    fill_in "Send to", :with => "irc://irc.example.org/foo"
    click_button "Update"
    click_button "Manual Build"

    repo.short_head
  end

  scenario "Notifying a successful build" do
    head = build(0)
    2.times{ @server.gets }

    msg = @server.gets
    assert msg.include?("#{head} successfully")
    assert msg.include?("http://www.example.com/my-test-project/builds/1")
  end

  scenario "Notifying a failed build" do
    head = build(1)
    2.times{ @server.gets }

    msg = @server.gets
    assert msg.include?("#{head} and failed")
    assert msg.include?("http://www.example.com/my-test-project/builds/1")
  end
end
