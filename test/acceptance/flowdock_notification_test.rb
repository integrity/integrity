require "helper/acceptance"

class FlowdockNotificationTest < Test::Unit::AcceptanceTestCase
  story <<-EOS
    As an administrator,
    I want to setup the Flowdock notifiers on my projects
    So that I get alerts with every build
  EOS

  setup do
    Notifier.register('Flowdock')

    @token   = "fc7795d580b6adacaa90f1ds24030s14a31a6522sed"
    @repo    = git_repo(:my_test_project)
    Project.gen(:my_test_project, :uri => @repo.uri)

    @api_url = "https://api.flowdock.com/v1/messages/team_inbox/#{@token}"
  end

  teardown do
    WebMock.reset!
    Notifier.available.replace({})
  end

  def commit(successful)
    successful ? @repo.add_successful_commit : @repo.add_failing_commit
    @repo.short_head
  end

  def build
    login_as "admin", "test"
    visit "/my-test-project"
    click_link "Edit"

    check "enabled_notifiers_flowdock"
    fill_in "API Token", :with => @token
    check "Notify on success?"
    click_button "Update"
    click_button "Manual Build"
  end

  scenario "Notifying a successful build" do
    head = commit(true)

    stub_request(:post, @api_url).to_return(
      :status => 200,
      :body   => {}.to_json)

    build

    assert_requested :post, @api_url
  end

  scenario "Notifying a failed build" do
    head = commit(false)
    stub_request(:post, @api_url).to_return(
      :status => 200,
      :body   => {}.to_json)

    build

    assert_requested :post, @api_url
  end
end
