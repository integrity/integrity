require "helper/acceptance"

class HTTPNotificationTest < Test::Unit::AcceptanceTestCase
  story <<-EOS
    As an administrator,
    I want to setup the HTTP notifiers on my projects
    So that I get alerts with every build
  EOS

  setup do
    load "integrity/notifier/http.rb"
    stub_request(:any, "http://example.com/success")
    stub_request(:any, "http://example.com/failure")
  end

  def build(status)
    repo = git_repo(:my_test_project)
    status.zero? ? repo.add_successful_commit : repo.add_failing_commit
    Project.gen(:my_test_project, :uri => repo.uri)

    login_as "admin", "test"
    visit "/my-test-project"
    click_link "Edit"

    check "enabled_notifiers_http"
    fill_in "Success", :with => "http://example.com/success"
    fill_in "Failure", :with => "http://example.com/failure"
    click_button "Update"
    click_button "Manual Build"

    repo.short_head
  end

  scenario "Notifying a successful build" do
    head = build(0)
    assert_requested :post, "http://example.com/success"
  end

  scenario "Notifying a failed build" do
    head = build(1)
    assert_requested :post, "http://example.com/failure"
  end
end
