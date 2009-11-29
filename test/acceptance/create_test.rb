require "helper/acceptance"

class CreateTest < Test::Unit::AcceptanceTestCase
  story <<-EOS
    As an administrator,
    I want to add projects to Integrity,
    So that I can know their status whenever I push code
  EOS

  setup do login_as "admin", "test" end

  scenario "Creating a public project" do
    visit "/new"
    fill_in "Name",            :with => "Integrity"
    fill_in "Repository URI",  :with => "git://github.com/foca/integrity.git"
    fill_in "Branch to track", :with => "master"
    fill_in "Build script",    :with => "rake"
    check   "Public project"
    click_button "Create Project"

    assert_have_tag("h1", :content => "Integrity")

    log_out
    visit "/"

    assert_have_tag("#projects a", :content => "Integrity")
  end

  scenario "Creating a private project" do
    visit "/new"
    fill_in "Name",            :with => "Integrity"
    fill_in "Repository URI",  :with => "git://github.com/foca/integrity.git"
    fill_in "Branch to track", :with => "master"
    fill_in "Build script",    :with => "rake"
    uncheck "Public project"
    click_button "Create Project"

    assert_have_tag("h1", :content => "Integrity")
    assert ! Project.first(:name => "Integrity").public?
  end

  scenario "Creating a project without filling-in required fields" do
    visit "/new"
    click_button "Create Project"

    assert_have_tag(".with_errors label", :content => "Name must not be blank")

    fill_in "Name",            :with => "Integrity"
    fill_in "Repository URI",  :with => "git://github.com/foca/integrity.git"
    click_button "Create Project"

    assert_have_tag("h1", :content => "Integrity")
  end

  scenario "Browsing to the creation formulary as a user" do
    log_out
    visit "/new"
    assert_equal 401, last_response.status
    assert_have_tag("h1", :content => "know the password?")
  end

  scenario "POST-ing direcly" do
    log_out
    post "/", "project_data[name]"    => "Integrity",
              "project_data[uri]"     => "git://github.com/foca/integrity.git",
              "project_data[branch]"  => "master",
              "project_data[command]" => "rake"
    assert_equal 401, last_response.status
    assert_have_tag("h1", :content => "know the password?")
  end
end
