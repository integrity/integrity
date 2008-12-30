require File.dirname(__FILE__) + "/../helpers"

class ApiTest < Test::Unit::AcceptanceTestCase
  story <<-EOF
    As a project owner,
    I want to be able to use GitHub as a build triggerer
    So that my project is build is made everytime I push to The Holly Hub
  EOF

  before(:each) do
    setup_and_reset_database!
    setup_log!
    set_and_create_export_directory!
  end

  after(:all) do
    destroy_all_git_repos
  end

  scenario "an unauthenticated request returns a 403" do
    pending "TODO"
  end

  scenario "receiving a build request with build_all_commits *enabled* builds all commits, most recent first" do
    pending "TODO"
  end

  scenario "it only build commits for the branch being monitored" do
    pending "TODO"
  end

  scenario "receiving a build request with an invalid payload returns an Invalid Request error" do
    pending "TODO"
  end

  scenario "receiving a build request with build_all_commits *disabled* only build HEAD" do
    Integrity.config[:build_all_commits] = false

    Project.gen(:my_test_project, :uri => git_repo(:my_test_project).path)

    git_repo(:my_test_project).add_failing_commit
    git_repo(:my_test_project).add_successful_commit
    head = git_repo(:my_test_project).head

    login_as "admin", "test"

    lambda do
      post "/my-test-project/push", :payload => payload(head, "master")
    end.should change(Build, :count).from(0).to(1)

    response_body.should == "Thanks, build started."
    response_code.should == 200

    visit "/my-test-project"
    response_body.should =~ /#{git_repo(:my_test_project).short_head} successfully/
    response_body.should =~ /This commit will work/
  end

  def payload(after, branch="master")
    { "after" => "#{after}",
      "ref"   => "refs/heads/#{branch}" }.to_json
  end

  def post(path, data)
    request_page(path, "post", data)
  end
end
