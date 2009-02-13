require File.dirname(__FILE__) + "/helpers"

class CreateProjectTest < Test::Unit::AcceptanceTestCase
  story <<-EOS
    As an administrator,
    I want to add projects to Integrity,
    So that I can know their status whenever I push code
  EOS

  scenario "an admin can create a public project" do
    Project.first(:permalink => "integrity").should be_nil

    login_as "admin", "test"

    visit "/new"

    fill_in "Name",            :with => "Integrity"
    fill_in "Git repository",  :with => "git://github.com/foca/integrity.git"
    fill_in "Branch to track", :with => "master"
    fill_in "Build script",    :with => "rake"
    check   "Public project"
    click_button "Create Project"

    Project.first(:permalink => "integrity").should_not be_nil
    response_body.should have_tag("h1", /Integrity/)

    log_out

    visit "/integrity"

    response_body.should have_tag("h1", /Integrity/)
  end

  scenario "an admin can create a private project" do
    Project.first(:permalink => "integrity").should be_nil

    login_as "admin", "test"

    visit "/new"

    fill_in "Name",            :with => "Integrity"
    fill_in "Git repository",  :with => "git://github.com/foca/integrity.git"
    fill_in "Branch to track", :with => "master"
    fill_in "Build script",    :with => "rake"
    uncheck "Public project"
    click_button "Create Project"

    response_body.should have_tag("h1", /Integrity/)
    Project.first(:permalink => "integrity").should_not be_nil

    log_out

    visit "/integrity"
    response_body.should have_tag("h1", /you don't know the password?/)
    response_code.should == 401
  end

  scenario "creating a project without required fields re-renders the new project form" do
    Project.first(:permalink => "integrity").should be_nil

    login_as "admin", "test"

    visit "/new"
    click_button "Create Project"

    response_body.should have_tag(".with_errors label", "Name must not be blank")
    Project.first(:permalink => "integrity").should be_nil

    fill_in "Name",            :with => "Integrity"
    fill_in "Git repository",  :with => "git://github.com/foca/integrity.git"
    click_button "Create Project"

    response_body.should have_tag("h1", /Integrity/)
    Project.first(:permalink => "integrity").should_not be_nil
  end

  scenario "a user can't see the new project form" do
    visit "/new"
    response_code.should == 401
    response_body.should have_tag("h1", /you don't know the password?/)
  end

  scenario "a user can't post the project data (bypassing the form)" do
    post "/", "project_data[name]"    => "Integrity",
              "project_data[uri]"     => "git://github.com/foca/integrity.git",
              "project_data[branch]"  => "master",
              "project_data[command]" => "rake"

    response_code.should == 401
    response_body.should have_tag("h1", /you don't know the password?/)
    Project.first(:permalink => "integrity").should be_nil
  end

  def post(path, data={})
    webrat.request_page(path, :post, data)
  end
end
