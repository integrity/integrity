require File.dirname(__FILE__) + "/../helpers"

class ManualBuildProjectTest < Test::Unit::AcceptanceTestCase
  story <<-EOS
    As an administrator,
    I want to manually build my project
    So that I know if it builds properly
  EOS
  
  scenario "clicking on 'Manual Build' triggers a successful build" do
    git_repo(:my_test_project).add_successful_commit
    Project.gen(:my_test_project, :uri => git_repo(:my_test_project).path)
    login_as "admin", "test"

    visit "/my-test-project"
    click_button "manual build"

    response_body.should have_tag("h1", /Built #{git_repo(:my_test_project).short_head} successfully/)
    response_body.should have_tag("blockquote p", /This commit will work/)  # commit message
    response_body.should have_tag("span.who",     /by: John Doe/)           # commit author
    response_body.should have_tag("span.when",    /today/)                  # commit date
    response_body.should have_tag("pre.output",   /Running tests.../)       # build output
  end
  
  scenario "clicking on 'Manual Build' triggers a failed build" do
    git_repo(:my_test_project).add_failing_commit
    Project.gen(:my_test_project, :uri => git_repo(:my_test_project).path)
    login_as "admin", "test"
    
    visit "/my-test-project"
    click_button "manual build"
    
    response_body.should have_tag("h1", /Built\s+#{git_repo(:my_test_project).short_head}\s+and failed/)
    response_body.should have_tag("blockquote p", /This commit will fail/)
  end

  scenario "fixing the build command and then rebuilding result in a successful build" do
    git_repo(:my_test_project).add_successful_commit
    Project.gen(:my_test_project, 
                :uri => git_repo(:my_test_project).path,
                :command => "ruby not-found.rb")

    login_as "admin", "test"

    visit "/my-test-project"
    click_button "manual build"
    response_body.should have_tag("h1", /failed/)

    visit "/my-test-project/edit"
    fill_in "Build script", :with => "./test"
    click_button "Update Project"
    
    visit "/my-test-project"
    click_button "Build the last commit"

    response_body.should have_tag("h1", /success/)
  end
  
  scenario "Successful builds should not display the 'Rebuild' button" do
    git_repo(:my_test_project).add_successful_commit
    Project.gen(:my_test_project, :uri => git_repo(:my_test_project).path)
    login_as "admin", "test"
    
    visit "/my-test-project"
    click_button "manual build"
    
    response_body.should_not have_tag("button", "Rebuild")
  end
  
  scenario "Failed builds should display the 'Rebuild' button" do
    git_repo(:my_test_project).add_failing_commit
    Project.gen(:my_test_project, :uri => git_repo(:my_test_project).path)
    login_as "admin", "test"
    
    visit "/my-test-project"
    click_button "manual build"
    
    response_body.should have_tag("button", "Rebuild")
  end
end
