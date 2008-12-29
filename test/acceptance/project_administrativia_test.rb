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
end
