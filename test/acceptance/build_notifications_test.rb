__END__
require "helper/acceptance"
require "helper/acceptance/notifier_helper"
require "helper/acceptance/email_notifier"

class BuildNotificationsTest < Test::Unit::AcceptanceTestCase
  include NotifierHelper

  story <<-EOS
    As an administrator,
    I want to setup notifiers on my projects
    So that I get alerts with every build
  EOS

  before(:each) do
    # This is needed before any available notifier is unset
    # in the global #before.
    # But, we need the reload this one because we remove_const
    # it in a test case. Sigh.
    load "helper/acceptance/textfile_notifier.rb"

    Notifier.register(Integrity::Notifier::Textfile)
    Notifier.register(Integrity::Notifier::Email)
  end

  scenario "an admin sets up a notifier and issue a manual build" do
    git_repo(:my_test_project).add_successful_commit
    Project.gen(:my_test_project, :uri => git_repo(:my_test_project).uri)
    rm_f "/tmp/textfile_notifications.txt"

    login_as "admin", "test"

    visit "/my-test-project"

    click_link "Edit Project"
    check "enabled_notifiers_textfile"
    fill_in "File", :with => "/tmp/textfile_notifications.txt"
    click_button "Update Project"

    click_button "manual build"

    notification = File.read("/tmp/textfile_notifications.txt")
    notification.should =~ /=== Built #{git_repo(:my_test_project).short_head} successfully ===/
    notification.should =~ /Build #{git_repo(:my_test_project).head} was successful/
    notification.should =~
      %r(http://www.example.com/my-test-project/commits/#{git_repo(:my_test_project).head})
    notification.should =~ /Commit Author: John Doe/
    notification.should =~ /Commit Date: (.+)/
    notification.should =~ /Commit Message: This commit will work/
    notification.should =~ /Build Output:\n\nRunning tests...\n/
  end

  scenario "an admin sets up the Textfile notifier but do not enable it" do
    git_repo(:my_test_project).add_successful_commit
    Project.gen(:my_test_project, :uri => git_repo(:my_test_project).uri)
    rm_f "/tmp/textfile_notifications.txt"

    login_as "admin", "test"

    visit "/my-test-project"

    click_link "Edit Project"
    uncheck "enabled_notifiers_textfile"
    fill_in "File", :with => "/tmp/textfile_notifications.txt"
    click_button "Update Project"

    click_button "manual build"

    assert ! File.file?("/tmp/textfile_notifications.txt")
  end

  scenario "an admin can setup a notifier without enabling it" do
    Project.gen(:integrity)

    login_as "admin", "test"

    visit "/integrity"
    click_link "Edit Project"
    fill_in_email_notifier
    click_button "Update Project"

    visit "/integrity/edit"
    assert_have_email_notifier
  end

  scenario "an admin enables the Textfile notifier and get rid of it later" do
    git_repo(:my_test_project).add_successful_commit
    Project.gen(:my_test_project, :uri => git_repo(:my_test_project).uri)

    login_as "admin", "test"
    visit "/my-test-project"

    click_link "Edit Project"
    check "enabled_notifiers_textfile"
    fill_in "File", :with => "/tmp/textfile_notifications.txt"
    click_button "Update Project"

    Notifier.send(:remove_const, :Textfile)
    Notifier.available.clear
    rm_f "/tmp/textfile_notifications.txt"

    click_button "manual build"

    assert ! File.file?("/tmp/textfile_notifications.txt")
  end

  scenario "an admin configures various notifiers accros multiple projects" do
    Project.first(:permalink => "integrity").should be_nil

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
    click_link "Edit Project"
    assert_have_email_notifier

    visit "/webrat"
    click_link "Edit Project"
    assert_have_email_notifier

    visit "/rails"
    click_link "Edit Project"
    assert_have_email_notifier
  end
end
