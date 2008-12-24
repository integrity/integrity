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
  end

  after(:all) do
    rm_r git_repository_directory
    rm_r export_directory
  end

  scenario "a user clicking on 'Manual Build' trigger a build that is successful" do
    project = Project.gen(:my_test_project)

    get "/#{project.permalink}"
    body.should =~ /No builds for this project, buddy/

    lambda do
      post "/#{project.permalink}/builds"
      status.should == 200
    end.should change(project.builds, :count).from(0).to(1)

    get "/#{project.permalink}"
    body.should have_tag("h1", /Built\s*#{project.last_build.short_commit_identifier}\s*successfully/m)
    body.should have_tag("blockquote p", "readme")
    body.should have_tag("span.who")
    body.should have_tag("span.when", /today/)
    body.should have_tag("pre.output", /this is just because Build/)
  end

  scenario "a user clicks on 'Manual Build' and trigger a build that is unsuccessful" do
    project = Project.gen(:my_test_project, :command => "ruby not-found.rb")

    lambda do
      post "/#{project.permalink}/builds"
      status.should == 200
    end.should change(project.builds, :count).from(0).to(1)

    get "/#{project.permalink}"
    body.should have_tag("h1", /Built\s*#{project.last_build.short_commit_identifier}\s*and failed/m)
  end
end
