require "helper/acceptance"

class NotifoNotificationTest < Test::Unit::AcceptanceTestCase
  story <<-EOS
    As an administrator,
    I want to setup the notifo notifiers on my projects
    So that I get alerts with every build
  EOS

  setup do
    load "integrity/notifier/notifo.rb"

    @token   = "74515bc044df6594fbdb761b12a42f8028e14588"
    @account = "test_provider"
    @recipient = "test_user"
    @subscribe_url = "https://#{@account}:#{@token}@api.notifo.com/v1/subscribe_user"
    @notification_url = "https://#{@account}:#{@token}@api.notifo.com/v1/send_notification"
    @repo    = git_repo(:my_test_project)
    Project.gen(:my_test_project, :uri => @repo.uri)

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
    click_link "Edit"

    check "enabled_notifiers_notifo"
    fill_in "Service Account", :with => @account
    fill_in "Recipients", :with => @recipient
    fill_in "Token", :with => @token
    check "Notify on success?"
    click_button "Update"
    click_button "Manual Build"
  end

  scenario "Notifying a successful build" do
    head = commit(true)

    response_ok = { "status" => "success",
                    "response_code" => 2201,
                    "response_message" => "OK" }.to_json

    stub_request(:post, @subscribe_url).to_return(:body => response_ok)
    stub_request(:post, @notification_url).to_return(:body => response_ok)

    build

    assert_requested :post, @subscribe_url
    assert_requested :post, @notification_url
  end

  scenario "Notifying a failed build" do
    head = commit(false)

    response_ok = { "status" => "success",
                    "response_code" => 2201,
                    "response_message" => "OK" }.to_json

    stub_request(:post, @subscribe_url).to_return(:body => response_ok)
    stub_request(:post, @notification_url).to_return(:body => response_ok)

    build

    assert_requested :post, @subscribe_url
    assert_requested :post, @notification_url

  end
end
