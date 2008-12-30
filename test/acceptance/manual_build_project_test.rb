require File.dirname(__FILE__) + "/../helpers"

class ManualBuildProjectTest < Test::Unit::AcceptanceTestCase
  story <<-EOS
    As an administrator,
    I want to manually build my project
    So that I know if it build properly
  EOS
  
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
    pending "either webrat or our sinatra app are escaping the form params once too many times"
    
    git_repo(:my_test_project).add_successful_commit
    project = Project.gen(:my_test_project, :uri => git_repo(:my_test_project).path,
                          :command => "ruby not-found.rb")
    login_as "admin", "test"

    visit "/my-test-project"
    click_button "manual build"
    response_body.should have_tag("h1", /failed/)

    # FIXME: this is because of a bug in the way webrat fils in forms. or in app.rb
    # FIXME: visit "/my-test-project/edit"
    # FIXME: fill_in "Build script", :with => "./test"
    # FIXME: click_button "Update Project"
    project.update_attributes(:command => "./test")

    Project.first(:permalink => "my-test-project").command.should == "./test"

    reloads

    visit "/my-test-project"
    click_button "Request Manual Build"

    response_body.should have_tag("h1", /success/)
  end
end
