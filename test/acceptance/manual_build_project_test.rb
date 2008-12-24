require File.dirname(__FILE__) + "/../helpers"

class ManualBuildProjectTest < Test::Unit::AcceptanceTestCase
  story <<-EOS
    As an user, 
    I want to manually build my project
    So that I know if it build properly
  EOS
  
  before(:each) do
    setup_and_reset_database!
    set_and_create_export_directory!
    ignore_logs!
  end

  scenario "a user clicking on 'Manual Build' trigger a build that is successful" do
    project = Project.gen(:shout_bot)

    get "/shoutbot"
    body.should =~ /No builds for this project, buddy/

    lambda do
      post "/shoutbot/builds"
    end.should change(project.builds, :count).from(0).to(1)

    get "/shoutbot"
    body.should have_tag("h1", /Built\s*#{project.last_build.short_commit_identifier}\s*successfully/m)
    body.should have_tag("blockquote p", "gem!")
    body.should have_tag("span.who", /Simon Rozet/)
    body.should have_tag("span.when", /Nov 19th/)
    body.should have_tag("pre.output", /16 examples, 0 failures, 1 pending/)
  end

  scenario "a user clicks on 'Manual Build' and trigger a build that is unsuccessful" do
    project = Project.gen(:shout_bot, :command => "cat /not/found/file.txt")

    lambda do
      post "/shoutbot/builds"
    end.should change(project.builds, :count).from(0).to(1)

    get "/shoutbot"
    body.should have_tag("h1", /Built\s*#{project.last_build.short_commit_identifier}\s*and failed/m)
  end
end
