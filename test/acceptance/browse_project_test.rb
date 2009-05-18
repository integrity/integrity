require File.dirname(__FILE__) + "/../helpers/acceptance"

class BrowsePublicProjectsTest < Test::Unit::AcceptanceTestCase
  story <<-EOS
    As a user,
    I want to browse public projects on Integrity,
    So I can follow the status of my favorite OSS projects
  EOS

  scenario "a user can see a public project listed on the home page" do
    Project.gen(:integrity, :public => true)
    Project.gen(:my_test_project, :public => true)

    visit "/"

    assert_have_tag("a", :content => "Integrity")
    assert_have_tag("a", :content => "My Test Project")
  end

  scenario "a user can't see a private project listed on the home page" do
    Project.gen(:my_test_project, :public => false)
    Project.gen(:integrity, :public => true)

    visit "/"

    assert_have_no_tag("a", :content => "My Test Project")
    assert_have_tag("a", :content => "Integrity")
  end

  scenario "a user can see the projects status on the home page" do
    integrity = Project.gen(:integrity, :commits => 3.of { Commit.gen(:successful) })
    test      = Project.gen(:my_test_project, :commits => 2.of { Commit.gen(:failed) })
    no_build  = Project.gen(:name => "none yet", :public => true)
    building  = Project.gen(:name => "building", :public => true,
                            :commits => 1.of{ Commit.gen(:building) })

    visit "/"

    assert_have_tag("li[@class~=success]",
      :content => "Built #{integrity.last_commit.short_identifier} successfully")

    assert_have_tag("li[@class~=failed]",
      :content => "Built #{test.last_commit.short_identifier} and failed")

    assert_have_tag("li[@class~=blank]", :content => "Never built yet")

    assert_have_tag("li[@class~=building]", :content => "Building!")
  end

  scenario "a user clicking through a link on the home page for a public project arrives at the project page" do
    Project.gen(:my_test_project, :public => true)

    visit "/"
    click_link "My Test Project"

    assert_have_tag("h1", :content => "My Test Project")

    # He can then go back to the project listing
    click_link "projects"
    assert_have_tag("a", :content => "My Test Project")
  end

  scenario "a user gets a 404 when browsing to an unexisting project" do
    visit "/who-are-you"

    response_code.should == 404
    assert_have_tag("h1", :content => "you seem a bit lost, sir")
  end

  scenario "a user browsing to the url of a private project gets a 401" do
    Project.gen(:my_test_project, :public => false)

    visit "/my-test-project"

    response_code.should == 401
    assert_have_tag("h1", :content => "know the password?")
  end

  scenario "an admin can browse to a private project just fine" do
    Project.gen(:my_test_project, :public => false)

    login_as "admin", "test"

    visit "/"
    click_link "My Test Project"

    assert_have_tag("h1", :content => "My Test Project")
  end

  scenario "a user browsing to a public project with no build see a friendly message" do
    project = Project.gen(:my_test_project, :public => true)

    visit "/my-test-project"
    assert_contain("No builds for this project, buddy")
  end

  scenario "an admin browsing to a private project with no build see a friendly message" do
    Project.gen(:my_test_project, :public => false)

    login_as "admin", "test"
    visit "/my-test-project"

    assert_contain("No builds for this project, buddy")
  end
end
