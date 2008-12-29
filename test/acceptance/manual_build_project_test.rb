require File.dirname(__FILE__) + "/../helpers"

class ManualBuildProjectTest < Test::Unit::AcceptanceTestCase
  story <<-EOS
    As an administrator,
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

  scenario "clicking on 'Manual Build' triggers a successful build" do
    git_repo(:my_test_project).add_successful_commit
    Project.gen(:my_test_project, :uri => git_repo(:my_test_project).path)
    login_as "admin", "test"

    visit "/my-test-project"
    click_button "manual build"

    response_body.should have_tag("h1", /Built\s+#{git_repo(:my_test_project).head}\s+successfully/)
    response_body.should have_tag("blockquote p", /This commit will work/)  # commit message
    response_body.should have_tag("span.who",     /by:\s+John Doe/)         # commit author
    response_body.should have_tag("span.when",    /today/)                  # commit date
    response_body.should have_tag("pre.output",   /Running tests.../)       # build output
  end

  scenario "clicking on 'Manual Build' triggers a failed build" do
    git_repo(:my_test_project).add_failing_commit
    Project.gen(:my_test_project, :uri => git_repo(:my_test_project).path)
    login_as "admin", "test"
    
    visit "/my-test-project"
    click_button "manual build"
    
    response_body.should have_tag("h1", /Built\s+#{git_repo(:my_test_project).head}\s+and failed/)
    response_body.should have_tag("blockquote p", /This commit will fail/)
  end

  scenario "fixing the build command and then rebuilding result in a successful build" do
    git_repo(:my_test_project).add_successful_commit
    project = Project.gen(:my_test_project, :uri => git_repo(:my_test_project).path,
                          :command => "ruby not-found.rb")
    login_as "admin", "test"

    visit "/my-test-project"
    click_button "manual build"
    response_body.should have_tag("h1", /failed/)

    # FIXME: command is set to './"escape code for /"test because of either
    # a bug in Webrat or in app.rb (escaping related)
=begin
    visit "/my-test-project/edit"
    fill_in "Build script", :with => "./test"
    click_button "Update Project"
=end
    project.update_attributes(:command => "./test")

    Project.first(:permalink => "my-test-project").command.should == "./test"

    reloads

    visit "/my-test-project"
    click_button "Request Manual Build"

    response_body.should have_tag("h1", /success/)
  end
end
