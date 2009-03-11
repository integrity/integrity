require File.dirname(__FILE__) + "/helpers"

class NotifierConfigIssues < Test::Unit::AcceptanceTestCase
  story <<-EOS
    As an administrator,
    I want to add multiple projects to Integrity,
    So that I can be certain notifiers remain functional (cf #43)
  EOS

  before(:each) do
    # This is needed before any available notifier is unset
    # in the global #before
    load File.dirname(__FILE__) + "/../helpers/acceptance/email_notifier.rb"
  end

  def fill_in_email_notifier
    fill_in "notifiers[Email][to]",     :with => "quentin@example.com"
    fill_in "notifiers[Email][from]",   :with => "ci@example.com"
    fill_in "notifiers[Email][user]",   :with => "inspector"
    fill_in "notifiers[Email][pass]",   :with => "gadget"
    fill_in "notifiers[Email][auth]",   :with => "simple"
    fill_in "notifiers[Email][domain]", :with => "example.com"
  end

  def fill_in_project_info(name, repo)
    fill_in "Name",            :with => name
    fill_in "Git repository",  :with => repo
    fill_in "Branch to track", :with => "master"
    fill_in "Build script",    :with => "rake"
    check   "Public project"

    fill_in_email_notifier
  end

  def assert_have_email_notifier
    assert_have_tag "input#email_notifier_to[@value='quentin@example.com']"
    assert_have_tag "input#email_notifier_from[@value='ci@example.com']"
    assert_have_tag "input#email_notifier_user[@value='inspector']"
    assert_have_tag "input#email_notifier_pass[@value='gadget']"
    assert_have_tag "input#email_notifier_auth[@value='simple']"
    assert_have_tag "input#email_notifier_domain[@value='example.com']"
  end

  def add_project(name, repo)
    visit "/new"
    fill_in_project_info(name, repo)
    click_button "Create Project"

    assert_have_tag("h1", :content => name)
    click_link 'Edit Project'
    assert_have_email_notifier
  end

  def edit_project(name)
    visit "/#{name}"
    click_link "Edit Project"
    assert_have_email_notifier
    fill_in :branch, :with => "testing"
    click_button "Update Project"
  end

  scenario "an admin can create a public project and retain mailer info" do
    Project.first(:permalink => "integrity").should be_nil

    login_as "admin", "test"

    visit "/"
    add_project  "Integrity", "git://github.com/foca/integrity.git"
    edit_project "integrity"

    visit "/integrity"
    click_link "Edit Project"

    assert_have_email_notifier
  end

  scenario "an admin can create multiple public projects" do
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
