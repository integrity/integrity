require File.dirname(__FILE__) + "/../helpers"

class DeleteProjectTest < Test::Unit::AcceptanceTestCase
  story <<-EOS
    As an administrator,
    I want to delete projects I don't care about anymore
    So that Integrity isn't cluttered with unimportant projects
  EOS

  scenario "an admin can delete a project from the 'Edit Project' screen" do
    Project.generate(:integrity, :commits => 4.of { Commit.gen })

    login_as "admin", "test"

    visit "/integrity"
    click_link "Edit Project"

    click_button "Yes, I'm sure, nuke it"

    visit "/"
    response_body.should_not have_tag("ul#projects", "Integrity")

    visit "/integrity"
    response_code.should == 404
  end

  scenario "an admin can delete a project with an invalid SCM URI just fine" do
    Project.generate(:integrity, :uri => "unknown://example.org")

    login_as "admin", "test"

    visit "/integrity/edit"

    click_button "Yes, I'm sure, nuke it"

    visit "/integrity"
    response_code.should == 404
  end

  scenario "a user can't delete a project by doing a manual DELETE request" do
    Project.gen(:integrity)

    delete "/integrity"
    response_code.should == 401

    visit "/integrity"
    response_body.should have_tag("h1", /Integrity/)
  end

  def delete(path, data={})
    webrat.request_page(path, :delete, data)
  end
end
