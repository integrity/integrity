require "helper/acceptance"

class IRCNotificationTest < Test::Unit::AcceptanceTestCase
  story <<-EOS
    As an administrator,
    I want to setup the IRC notifiers on my projects
    So that I get alerts with every build
  EOS

  before(:each) do
    # This is needed before any available notifier is remove_const'd
    # in the global #before.
    load "integrity/notifier/irc.rb"
  end

  # thanks harryv
   class MockSocket
    attr_accessor :in, :out
    def gets() @in.gets end
    def puts(m) @out.puts(m) end
    def eof?() true end
  end

  setup do
    @socket, @server = MockSocket.new, MockSocket.new
    @socket.in, @server.out = IO.pipe
    @server.in, @socket.out = IO.pipe

    stub(TCPSocket).open(anything, anything) {@socket}
  end

  scenario "Notifying a successful build" do
    repo = git_repo(:my_test_project)
    repo.add_successful_commit
    Project.gen(:my_test_project, :uri => repo.uri)

    login_as "admin", "test"
    visit "/my-test-project"
    click_link "Edit Project"

    check "enabled_notifiers_irc"
    fill_in "Send to", :with => "irc://irc.example.org/foo"
    click_button "Update"
    click_button "Manual Build"

    2.times{ @server.gets }

    assert @server.gets.include?("#{repo.short_head} successfully")
    assert @server.gets.
      include?("http://www.example.com/my-test-project/builds/1")
  end

  scenario "Notifying a failed build" do
    repo = git_repo(:my_test_project)
    repo.add_failing_commit
    Project.gen(:my_test_project, :uri => repo.uri)

    login_as "admin", "test"
    visit "/my-test-project"
    click_link "Edit Project"

    check "enabled_notifiers_irc"
    fill_in "Send to", :with => "irc://irc.example.org/foo"
    click_button "Update"
    click_button "Manual Build"

    2.times{ @server.gets }

    assert @server.gets.include?("#{repo.short_head} and failed")
    assert @server.gets.
      include?("http://www.example.com/my-test-project/builds/1")
  end
end
