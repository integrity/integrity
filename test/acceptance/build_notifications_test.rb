require "helper/acceptance"
require "helper/acceptance/notifier_helper"
require "helper/acceptance/email_notifier"

class BuildNotificationsTest < Test::Unit::AcceptanceTestCase
  include NotifierHelper
  
  def textfile_notifications_path
    File.join(INTEGRITY_TEST_TMP, 'textfile_notifications.txt')
  end

  story <<-EOS
    As an administrator,
    I want to setup notifiers on my projects
    So that I get alerts with every build
  EOS

  setup do
    # This is needed before any available notifier is unset
    # in the global #before.
    # But, we need the reload this one because we remove_const
    # it in a test case. Sigh.
    load "helper/acceptance/textfile_notifier.rb"

    Notifier.register(Integrity::Notifier::Textfile)
    Notifier.register(Integrity::Notifier::Email)
  end

  scenario "an admin sets up a notifier and issues a manual build" do
    git_repo(:my_test_project).add_successful_commit
    Project.gen(:my_test_project, :uri => git_repo(:my_test_project).uri)
    rm_f textfile_notifications_path

    login_as "admin", "test"

    visit "/my-test-project"

    click_link "Edit"
    check "enabled_notifiers_textfile"
    fill_in "File", :with => textfile_notifications_path
    click_button "Update Project"

    click_button "manual build"

    notification = File.read(textfile_notifications_path)
    assert_match(/=== Built #{git_repo(:my_test_project).short_head} successfully ===/, notification)
    #assert_match /Build #{git_repo(:my_test_project).head} was successful/, notification
    #assert_match %r(http://www.example.com/my-test-project/commits/#{git_repo(:my_test_project).head}), notification
    assert_match /Commit Author: John Doe/, notification
    assert_match /Commit Date: (.+)/, notification
    assert_match /Commit Message: master: This commit will work/, notification
    assert_match /Build Output:\n\nRunning tests...\n/, notification
  end

  scenario "an admin sets up the Textfile notifier but does not enable it" do
    git_repo(:my_test_project).add_successful_commit
    Project.gen(:my_test_project, :uri => git_repo(:my_test_project).uri)
    rm_f textfile_notifications_path

    login_as "admin", "test"

    visit "/my-test-project"

    click_link "Edit"
    uncheck "enabled_notifiers_textfile"
    fill_in "File", :with => textfile_notifications_path
    click_button "Update Project"

    click_button "manual build"

    assert ! File.file?(textfile_notifications_path)
  end

  scenario "an admin can setup a notifier without enabling it" do
    Project.gen(:integrity)

    login_as "admin", "test"

    visit "/integrity"
    click_link "Edit"
    fill_in_email_notifier
    click_button "Update Project"

    visit "/integrity/edit"
    assert_have_email_notifier
  end

  scenario "an admin enables the Textfile notifier and gets rid of it later" do
    git_repo(:my_test_project).add_successful_commit
    Project.gen(:my_test_project, :uri => git_repo(:my_test_project).uri)

    login_as "admin", "test"
    visit "/my-test-project"

    click_link "Edit"
    check "enabled_notifiers_textfile"
    fill_in "File", :with => textfile_notifications_path
    click_button "Update Project"

    Notifier.send(:remove_const, :Textfile)
    Notifier.available.clear
    rm_f textfile_notifications_path

    click_button "manual build"

    assert ! File.file?(textfile_notifications_path)
  end

  scenario "an admin configures various notifiers across multiple projects" do
    project = Project.first(:permalink => "integrity")
    assert_nil project

    login_as "admin", "test"

    visit "/"

    add_project "Integrity", "git://github.com/foca/integrity.git"
    click_link  "projects"

    add_project "Webrat", "git://github.com/brynary/webrat.git"
    click_link  "projects"

    add_project "Rails", "git://github.com/rails/rails.git"
    click_link  "projects"

    edit_project "integrity"
    edit_project "webrat"
    edit_project "rails"

    visit "/integrity"
    click_link "Edit"
    assert_have_email_notifier

    visit "/webrat"
    click_link "Edit"
    assert_have_email_notifier

    visit "/rails"
    click_link "Edit"
    assert_have_email_notifier
  end
end
