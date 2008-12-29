require File.dirname(__FILE__) + "/../helpers"

class ManualBuildProjectTest < Test::Unit::AcceptanceTestCase
  story <<-EOS
    As an user, 
    I want to manually build my project
    So that I know if it build properly
  EOS
  
  before(:each) do
    setup_and_reset_database!
    setup_log!
    set_and_create_export_directory!
  end

  after(:all) do
    destroy_all_git_repos
    rm_r export_directory
  end

  scenario "a user clicking on 'Manual Build' and triggers a successful build" do
    git_repo(:my_test_project).add_successful_commit
    Project.gen(:my_test_project, :uri => git_repo(:my_test_project).path)
    
    login_as "admin", "test"

    visit "/my-test-project"
    response_body.should include("No builds for this project, buddy")

    click_button "manual build"

    response_body.should =~ /Built\s+#{git_repo(:my_test_project).head}\s+successfully/
    response_body.should =~ /This commit will work/          # commit message
    response_body.should =~ /by:\s+John Doe/                 # commit author
    response_body.should =~ /today/                          # commit date
    response_body.should have_tag("pre", /Running tests.../) # build output
  end

  scenario "a user clicking on 'Manual Build' and triggers a failed build" do
    git_repo(:my_test_project).add_failing_commit
    Project.gen(:my_test_project, :uri => git_repo(:my_test_project).path)
    
    login_as "admin", "test"
    
    visit "/my-test-project"
    response_body.should include("No builds for this project, buddy")

    click_button "manual build"
    
    response_body.should =~ /Built\s+#{git_repo(:my_test_project).head}\s+and failed/
    response_body.should =~ /This commit will fail/          # commit message
  end
end
