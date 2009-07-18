require File.dirname(__FILE__) + "/../helpers/acceptance"

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

    assert_have_tag("h1", :content => "Integrity (test refactoring)")
  end

  scenario "making a public project private will hide it from the home page for non-admins" do
    Project.generate(:my_test_project, :public => true)

    visit "/"

    assert_contain("My Test Project")

    login_as "admin", "test"
    visit "/my-test-project"
    click_link "Edit Project"
    uncheck "Public project"
    click_button "Update Project"
    log_out
    visit "/"

    assert_have_no_tag("a", :content => "My Test Project")
  end

  scenario "making a private project public will show it in the home page for non-admins" do
    Project.generate(:my_test_project, :public => false)

    visit "/"

    assert_not_contain("My Test Project")

    login_as "admin", "test"

    visit "/my-test-project"
    click_link "Edit Project"

    check "Public project"
    click_button "Update Project"

    log_out

    visit "/"

    assert_have_tag("a", :content => "My Test Project")
  end

  scenario "a user can't edit a project's information" do
    Project.generate(:integrity)

    visit "/integrity"
    click_link "Edit Project"

    response_code.should == 401
  end

  scenario "public projects have a ticked 'public' checkbox on edit form" do
    Project.generate(:my_test_project, :public => true)

    login_as "admin", "test"
    visit "/my-test-project/edit"

    assert_have_tag('input[@type="checkbox"][@checked="checked"][@name="project_data[public]"]')
  end

  scenario "private projects have an unticked 'public' checkbox on edit form" do
    Project.generate(:my_test_project, :public => false)

    login_as "admin", "test"
    visit "/my-test-project/edit"

    assert_have_no_tag('input[@type="checkbox"][@checked][@name="project_data[public]"]')
  end

  scenario "after I uncheck the public checkbox, it should still be uncheck after I save" do
    Project.generate(:integrity, :public => true)

    login_as "admin", "test"
    visit "/integrity"
    click_link "Edit Project"

    assert_have_tag('input[@type="checkbox"][@checked="checked"][@name="project_data[public]"]')

    uncheck "project_public"
    click_button "Update Project"

    click_link "Edit Project"

    assert_have_no_tag('input[@type="checkbox"][@checked="checked"][@name="project_data[public]"]')
  end
end
