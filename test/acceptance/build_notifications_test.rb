require File.dirname(__FILE__) + "/helpers"
require File.dirname(__FILE__) + "/../helpers/acceptance/textfile_notifier"

class BuildNotificationsTest < Test::Unit::AcceptanceTestCase
  story <<-EOS
    As an administrator,
    I want to setup notifiers on my projects
    So that I get alerts with every build
  EOS

  scenario "an admin sets up a notifier for a project that didn't have any" do
    git_repo(:my_test_project).add_successful_commit
    Project.gen(:my_test_project, :notifiers => [], :uri => git_repo(:my_test_project).path)
    rm_f "/tmp/textfile_notifications.txt"

    login_as "admin", "test"

    visit "/my-test-project"

    click_link "Edit Project"
    check "enabled_notifiers_textfile"
    fill_in "File", :with => "/tmp/textfile_notifications.txt"
    click_button "Update Project"

    click_button "manual build"

    notification = File.read("/tmp/textfile_notifications.txt")
    notification.should =~ /=== Build #{git_repo(:my_test_project).short_head} was successful ===/
    notification.should =~ /Build #{git_repo(:my_test_project).head} was successful/
    notification.should =~ %r(http://integrity.example.org/my-test-project/builds/#{git_repo(:my_test_project).head})
    notification.should =~ /Commit Author: John Doe/
    notification.should =~ /Commit Date: (.+)/
    notification.should =~ /Commit Message: This commit will work/
    notification.should =~ /Build Output:\n\nRunning tests...\n/
  end
end
