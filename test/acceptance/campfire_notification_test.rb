require "helper/acceptance"

class CampfireNotificationTest < Test::Unit::AcceptanceTestCase
  story <<-EOS
    As an administrator,
    I want to setup the campfire notifiers on my projects
    So that I get alerts with every build
  EOS

  setup do
    load "integrity/notifier/campfire.rb"

    @token   = "fc7795d580b6adacaa90f1ds24030s14a31a6522sed"
    @account = "rush"
    @room    = "The Studio"
    @repo    = git_repo(:my_test_project)
    Project.gen(:my_test_project, :uri => @repo.uri)

    @id = 1337
    @room_url  = "https://#{@token}:x@#{@account}.campfirenow.com/rooms"
    @speak_url = "https://#{@token}:x@#{@account}.campfirenow.com/room/#{@id}/speak"
  end

  teardown do
    WebMock.reset_webmock
  end

  def commit(successful)
    successful ? @repo.add_successful_commit : @repo.add_failing_commit
    @repo.short_head
  end

  def build
    login_as "admin", "test"
    visit "/my-test-project"
    click_link "Edit Project"

    check "enabled_notifiers_campfire"
    fill_in "Subdomain", :with => @account
    fill_in "Room Name", :with => @room
    fill_in "API Token", :with => @token
    check "SSL?"
    check "Notify on success?"
    click_button "Update"
    click_button "Manual Build"
  end

  scenario "Notifying a successful build" do
    head = commit(true)
    payload = {
      'message' => {
       'type' => 'TextMessage',
       'body' => "Built #{head} successfully. http://www.example.com/my-test-project/builds/1"
      }
    }.to_json

    stub_request(:get, @room_url).to_return(:body => {'rooms' => [{'name' => @room, 'id' => @id}]}.to_json)
    stub_request(:post, @speak_url).to_return(
      :status => 201,
      :body   => {'message' => 'Accepted!'}.to_json)

    build

    assert_requested :get, @room_url
    assert_requested :post, @speak_url, :body => payload
  end

  scenario "Notifying a failed build" do
    head = commit(false)
    speak_payload = {
      'message' => {
       'type' => 'TextMessage',
       'body' => "Built #{head} and failed. http://www.example.com/my-test-project/builds/1"
      }
    }.to_json

    build_commit = @repo.commits.last
    paste_body = <<-EOM
Commit Message: #{build_commit["message"]}
Commit Date: #{DateTime.parse(build_commit["timestamp"])}
Commit Author: #{build_commit["author"]["name"]}

Running tests...

EOM

    paste_payload = {
      'message' => {
       'type' => 'PasteMessage',
       'body' => paste_body
      }
    }.to_json

    stub_request(:get, @room_url).to_return(:body => {'rooms' => [{'name' => @room, 'id' => @id}]}.to_json)
    stub_request(:post, @speak_url).to_return(
      :status => 201,
      :body   => {'message' => 'Accepted!'}.to_json)

    build

    assert_requested :get, @room_url, :times => 2

    [speak_payload, paste_payload].each do |payload|
      assert_requested :post, @speak_url, :body => payload
    end
  end
end
