require File.dirname(__FILE__) + "/../helpers"

class ProjectAdministrativiaTest < Test::Unit::AcceptanceTestCase
  story <<-EOS
    As an administrator,
    I want to be able to edit and delete a repo as well
    So that well, err, I do admin stuff!
  EOS

  before(:each) do
    setup_and_reset_database!
    enable_auth!
    login_as "admin", "test"
  end

  scenario "browsing to a project page and click on 'Yes, I'm sure, nuke it' destroy the project" do
    project = Project.generate(:integrity, :builds => 4.of { Build.gen })

    visit "/"
    click_link_within("#content", "Integrity")
    visit "/integrity/edit"

    lambda do
      click_button "Yes, I'm sure, nuke it"
    end.should change(Project, :count).from(1).to(0)

    visit "/"
    response_body.should_not have_tag("ul#projects li a", "Integrity")

    visit "/integrity"
    response_code.should == 404
  end

  scenario "browsing to a project page and click on edit brings me to the edit interface" do
    Project.generate(:integrity)

    visit "/"
    click_link_within("#content", "Integrity")
    click_link "Edit Project"

    # TODO
    response_body.should have_tag("form[@action='/integrity']")
  end

  scenario "editing a public project to make it privatre removes it from the homepage for users" do
    Project.generate(:my_test_project, :public => true)

    visit "/"
    # duplicates with #click_link but it makes me feel safer :-)
    response_body.should have_tag("ul#projects li a", /My Test Project/)
    click_link "My Test Project"
    click_link "Edit Project"
    uncheck "Public project"
    click_button "Update Project"

    reloads
    log_out

    visit "/"
    # FIXME: the ugly regexp is because of a bug in the way webrat fils in forms. or in app.rb
    response_body.should_not =~ /My.*?Test.*?Project/
  end
end
