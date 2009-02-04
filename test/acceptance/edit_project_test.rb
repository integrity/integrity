require File.dirname(__FILE__) + "/helpers"

class EditProjectTest < Test::Unit::AcceptanceTestCase
  story <<-EOS
    As an administrator,
    I want to be able to edit a project
    So that I can correct mistakes or update the project after a change
  EOS

  scenario "an admin can edit the project information" do
    Project.generate(:integrity)

    login_as "admin", "test"

    visit "/integrity"
    click_link "Edit Project"

    fill_in "Name",            :with => "Integrity (test refactoring)"
    fill_in "Branch to track", :with => "test-refactoring"
    click_button "Update Project"

    response_body.should have_tag("h1", /Integrity \(test refactoring\)/)
  end

  scenario "making a public project private will hide it from the home page for non-admins" do
    Project.generate(:my_test_project, :public => true)

    visit "/"
    response_body.should =~ /My Test Project/

    login_as "admin", "test"

    visit "/my-test-project"
    click_link "Edit Project"

    uncheck "Public project"
    click_button "Update Project"

    log_out

    visit "/"
    response_body.should_not have_tag("a", /My Test Project/)
  end

  scenario "making a private project public will show it in the home page for non-admins" do
    Project.generate(:my_test_project, :public => false)

    visit "/"
    response_body.should_not =~ /My Test Project/

    login_as "admin", "test"

    visit "/my-test-project"
    click_link "Edit Project"

    check "Public project"
    click_button "Update Project"

    log_out

    visit "/"
    response_body.should have_tag("a", /My Test Project/)
  end

  scenario "an admin can see the push URL on the edit page" do
    disable_auth!
    Project.generate(:my_test_project)

    visit "/my-test-project"
    click_link "Edit Project"

    response_body.should have_tag("#push_url", "http://integrity.example.org/my-test-project/push")
  end

  scenario "a user can't edit a project's information" do
    Project.generate(:integrity)

    visit "/integrity"
    click_link "Edit Project"

    response_code.should == 401
  end
end
