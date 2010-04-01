require "helper/acceptance"

class HomepageTest < Test::Unit::AcceptanceTestCase
  story <<-EOS
    As a user,
    I want to browse my project from Integrity's homepage
    So I can follow the status of my various projects
  EOS

  scenario "Private projects aren't shown" do
    Project.gen(:my_test_project, :public => false)
    Project.gen(:integrity, :public => true)

    visit "/"

    assert_have_no_tag("a", :content => "My Test Project")
    assert_have_tag("a", :content => "Integrity")
  end

  scenario "I can see the state of my various projects" do
    Project.gen(:successful)
    Project.gen(:failed)
    Project.gen(:building)
    Project.gen(:blank)

    visit "/"

    # TODO
    assert_have_tag("li[@class~=success]")
    assert_have_tag("li[@class~=failed]")

    assert_have_tag("li[@class~=blank]",    :content => "Never built yet")
    assert_have_tag("li[@class~=building]", :content => "Building!")
  end

  scenario "Clicking on a project from the homepage" do
    Project.gen(:my_test_project, :public => true)

    visit "/"
    click_link "My Test Project"

    assert_have_tag("h1", :content => "My Test Project")

    click_link "projects"

    assert_have_tag("a", :content => "My Test Project")
  end

  scenario "Browsing to an unknown project" do
    visit "/foobiz"
    assert last_response.not_found?
    assert_have_tag("h1", :content => "you seem a bit lost, sir")
  end

  scenario "Browsing to a private project" do
    Project.gen(:name => "Secret", :public => false)

    visit "/secret"
    assert_equal 401, last_response.status
    assert_have_tag("h1", :content => "know the password?")
  end

  scenario "Signing-in as an admin and browsing to a private project" do
    Project.gen(:my_test_project, :public => false)

    login_as "admin", "test"
    visit "/"
    click_link "My Test Project"
    assert_have_tag("h1", :content => "My Test Project")
  end
end
