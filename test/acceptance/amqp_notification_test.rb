require "helper/acceptance"
require 'bunny'

class AMQPNotificationTest < Test::Unit::AcceptanceTestCase
  story <<-EOS
    As an administrator,
    I want to setup the AMQP notifiers on my projects
    So that I get an AMQP message sent to a given queue for every build
  EOS

  setup do
    load "integrity/notifier/amqp.rb"
  end

  def build(status)
    repo = git_repo(:my_test_project)
    status.zero? ? repo.add_successful_commit : repo.add_failing_commit
    Project.gen(:my_test_project, :uri => repo.uri)

    login_as "admin", "test"
    visit "/my-test-project"
    click_link "Edit"

    check "enabled_notifiers_amqp"
    fill_in "Host", :with => "localhost"
    fill_in "Exchange", :with => "test"
    click_button "Update"
    click_button "Manual Build"

    repo.short_head
  end

  scenario "Notifying a build" do

    msg = JSON.generate({
      "name"    => "My Test Project",
      "status"  => "success",
      "url"     => "http://www.example.com/my-test-project/builds/1",
      "author"  => "John Doe",
      "message" => "master: This commit will work"
    })

    mock_rabbit = Bunny.new
    mock(mock_rabbit).start {}
    mock(mock_rabbit).stop {}
    mock(mock_rabbit).exchange('test', :type => :fanout) { mock!.publish(msg) {} }
    stub(Bunny).new { mock_rabbit }
    head = build(0)
  end

end
