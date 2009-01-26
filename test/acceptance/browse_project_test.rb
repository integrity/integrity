require File.dirname(__FILE__) + "/../helpers"

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

    response_body.should have_tag("a", /Integrity/)
    response_body.should have_tag("a", /My Test Project/)
  end

  scenario "a user can't see a private project listed on the home page" do
    Project.gen(:my_test_project, :public => false)
    Project.gen(:integrity, :public => true)

    visit "/"

    response_body.should_not have_tag("a", /My Test Project/)
    response_body.should have_tag("a", /Integrity/)
  end

  scenario "a user can see the projects status on the home page" do
    integrity = Project.gen(:integrity, :commits => 3.of { Commit.gen(:successful) })
    test      = Project.gen(:my_test_project, :commits => 2.of { Commit.gen(:failed) })
    no_build  = Project.gen(:public => true, :building => false)
    building  = Project.gen(:public => true, :building => true)

    visit "/"
    
    response_body.should =~ /Built #{integrity.last_commit.short_identifier} successfully/m
    response_body.should =~ /Built #{test.last_commit.short_identifier} and failed/m
    response_body.should =~ /Never built yet/
    response_body.should =~ /Building!/
  end

  scenario "a user clicking through a link on the home page for a public project arrives at the project page" do
    Project.gen(:my_test_project, :public => true)

    visit "/"
    click_link "My Test Project"

    response_body.should have_tag("h1", /My Test Project/)
  end

  scenario "a user gets a 404 when browsing to an unexisting project" do
    visit "/who-are-you"

    response_code.should == 404
    response_body.should have_tag("h1", /you seem a bit lost, sir/)
  end

  scenario "a user browsing to the url of a private project gets a 401" do
    Project.gen(:my_test_project, :public => false)

    visit "/my-test-project"

    response_code.should == 401
    response_body.should have_tag("h1", /you don't know the password?/)
  end

  scenario "an admin can browse to a private project just fine" do
    Project.gen(:my_test_project, :public => false)

    login_as "admin", "test"

    visit "/"
    click_link "My Test Project"

    response_body.should have_tag("h1", /My Test Project/)
  end

  scenario "a user browsing to a public project with no build see a friendly message" do
    project = Project.gen(:my_test_project, :public => true)

    visit "/my-test-project"
    response_body.should include("No builds for this project, buddy")
  end

  scenario "an admin browsing to a private project with no build see a friendly message" do
    Project.gen(:my_test_project, :public => false)

    login_as "admin", "test"
    visit "/my-test-project"

    response_body.should include("No builds for this project, buddy")
  end
end
