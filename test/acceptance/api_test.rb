require File.dirname(__FILE__) + "/../helpers/acceptance"

class ApiTest < Test::Unit::AcceptanceTestCase
  story <<-EOF
    As a project owner,
    I want to be able to use GitHub as a build triggerer
    So that my project is built everytime I push to the Holy Hub
  EOF

  def payload(after, branch="master", commits=[])
    payload = { "after" => "#{after}", "ref" => "refs/heads/#{branch}" }
    payload["commits"] = commits if commits.any?
    payload.to_json
  end

  def post(path, data)
    request_page(path, "post", data)
  end

  scenario "it only build commits for the branch being monitored" do
    repo = git_repo(:my_test_project) # initial commit && successful commit
    Project.gen(:my_test_project, :uri => repo.path, :branch => "my-branch")

    basic_auth "admin", "test"

    lambda do
      post "/my-test-project/push", :payload => payload(repo.head, "master", repo.commits)
      response_code.should == 422
    end.should_not change(Build, :count)

    visit "/my-test-project"

    assert_contain("No builds for this project")
  end

  scenario "receiving a build request with build_all_commits *enabled* builds all commits, most recent first" do
    Integrity.config[:build_all_commits] = true

    repo = git_repo(:my_test_project) # initial commit && successful commit
    3.times do |i|
      repo.add_commit("commit #{i}") do
        system "echo commit_#{i} >> test-file"
        system "git add test-file &>/dev/null"
      end
    end

    Project.gen(:my_test_project, :uri => repo.path, :command => "echo successful", :branch => "master")

    basic_auth "admin", "test"
    post "/my-test-project/push", :payload => payload(repo.head, "master", repo.commits)

    visit "/my-test-project"

    assert_have_tag("h1", :content => "Built #{git_repo(:my_test_project).short_head} successfully")
    assert_have_tag(".attribution", :content => "by John Doe")

    assert_have_tag("#previous_builds li", :count => 4)
  end

  scenario "receiving a build request with build_all_commits *disabled* only builds the last commit passed" do
    Integrity.config[:build_all_commits] = false

    Project.gen(:my_test_project, :uri => git_repo(:my_test_project).path)

    git_repo(:my_test_project).add_failing_commit
    git_repo(:my_test_project).add_successful_commit
    head = git_repo(:my_test_project).head

    basic_auth "admin", "test"
    post "/my-test-project/push", :payload => payload(head, "master", git_repo(:my_test_project).commits)

    response_code.should == 201

    visit "/my-test-project"

    assert_have_tag("h1", :content => "Built #{git_repo(:my_test_project).short_head} successfully")

    assert_have_no_tag("#previous_builds li")
  end

  scenario "an unauthenticated request returns a 401" do
    Project.gen(:my_test_project, :uri => git_repo(:my_test_project).path)
    head = git_repo(:my_test_project).head
    post "/my-test-project/push", :payload => payload(head, "master")

    response_code.should == 401
  end

  scenario "receiving a build request with an invalid payload returns an Invalid Request error" do
    Project.gen(:my_test_project, :uri => git_repo(:my_test_project).path)

    basic_auth "admin", "test"

    post "/my-test-project/push", :payload => "foo"
    response_code.should == 422
  end
end
