require "helper/acceptance"

class HTTPNotificationTest < Test::Unit::AcceptanceTestCase
  story <<-EOS
    As an administrator,
    I want to setup the HTTP notifiers on my projects
    So that I get a POST to given URL for every build
  EOS

  setup do
    load "integrity/notifier/http.rb"
    stub_request(:any, "http://example.com/")
  end

  def build(status)
    repo = git_repo(:my_test_project)
    status.zero? ? repo.add_successful_commit : repo.add_failing_commit
    Project.gen(:my_test_project, :uri => repo.uri)

    login_as "admin", "test"
    visit "/my-test-project"
    click_link "Edit"

    check "enabled_notifiers_http"
    fill_in "URL", :with => "http://example.com/"
    click_button "Update"
    click_button "Manual Build"

    repo.short_head
  end

  scenario "Notifying a build" do
    head = build(0)
    assert_requested :post, "http://example.com/"
  end
end
