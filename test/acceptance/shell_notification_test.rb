require "helper/acceptance"

class ShellNotificationTest < Test::Unit::AcceptanceTestCase
  story <<-EOS
    As an administrator,
    I want to setup the shell notifiers on my projects
    So that I get alerts with every build
  EOS

  setup do
    Notifier.register('Shell')

    @success_cmd = "echo \"success\""
    @failed_cmd = "echo \"failed\""

    @repo    = git_repo(:my_test_project)
    Project.gen(:my_test_project, :uri => @repo.uri)
  end

  teardown do
    WebMock.reset!
  end

  def commit(successful)
    successful ? @repo.add_successful_commit : @repo.add_failing_commit
    @repo.short_head
  end

  def build
    login_as "admin", "test"
    visit "/my-test-project"
    click_link "Edit"

    check "enabled_notifiers_shell"
    fill_in "On build success", :with => @success_cmd
    fill_in "On build fail", :with => @failed_cmd
    check "Notify on success?"
    click_button "Update"
    click_button "Manual Build"
  end

  scenario "Notifying a successful build" do
    head = commit(true)

    response_success = `#{@success_cmd}`

    build

    assert_equal "success\n", response_success
  end

  scenario "Notifying a failed build" do
    head = commit(false)

    response_fail = `#{@failed_cmd}`

    build

    assert_equal "failed\n", response_fail
  end
end
