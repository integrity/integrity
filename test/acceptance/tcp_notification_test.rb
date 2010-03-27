require "helper/acceptance"

class TCPNotificationTest < Test::Unit::AcceptanceTestCase
  story <<-EOS
    As an administrator,
    I want to setup the TCP notifiers on my projects
    So that I get alerts with every build
    Using Corey's awesome  http://github.com/atmos/irccat-nodejs
  EOS

  setup do
    load "integrity/notifier/tcp.rb"
    @server = mock_socket
  end

  def build(status)
    repo = git_repo(:my_test_project)
    status.zero? ? repo.add_successful_commit : repo.add_failing_commit
    Project.gen(:my_test_project, :uri => repo.uri)

    login_as "admin", "test"
    visit "/my-test-project"
    click_link "Edit Project"

    check "enabled_notifiers_tcp"
    fill_in "Send to", :with => "tcp://0.0.0.0:1234"
    click_button "Update"
    click_button "Manual Build"

    repo.short_head
  end

  scenario "Notifying a successful build" do
    head = build(0)

    msg = @server.gets
    assert msg.include?("#{head} successfully")
    assert msg.include?("http://www.example.com/my-test-project/builds/1")
  end

  scenario "Notifying a failed build" do
    head = build(1)

    msg = @server.gets
    assert msg.include?("#{head} and failed")
    assert msg.include?("http://www.example.com/my-test-project/builds/1")
  end
end
