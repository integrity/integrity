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
    create_git_repository!
    set_and_create_export_directory!
    login_as "admin", "test"
  end

  after(:all) do
    rm_r git_repository_directory
    rm_r export_directory
  end

  scenario "a user clicking on 'Manual Build' trigger a build that is successful" do
    project = Project.gen(:my_test_project)

    visit "/#{project.permalink}"
    response_body.should include("No builds for this project, buddy")

    lambda do
      request_page "/#{project.permalink}/builds", "post", {}
      response_code.should == 200
    end.should change(project.builds, :count).from(0).to(1)

    visit "/#{project.permalink}"
    response_body.should have_tag("h1", /Built\s*#{project.last_build.short_commit_identifier}\s*successfully/m)
    response_body.should have_tag("blockquote p", "readme")
    response_body.should have_tag("span.who")
    response_body.should have_tag("span.when", /today/)
    response_body.should have_tag("pre.output", /this is just because Build/)
  end

  scenario "a user clicks on 'Manual Build' and trigger a build that is unsuccessful" do
    project = Project.gen(:my_test_project, :command => "ruby not-found.rb")

    lambda do
      request_page "/#{project.permalink}/builds", "post", {}
      response_code.should == 200
    end.should change(project.builds, :count).from(0).to(1)

    visit "/#{project.permalink}"
    response_body.should have_tag("h1", /Built\s*#{project.last_build.short_commit_identifier}\s*and failed/m)
  end
end
