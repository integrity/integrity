require File.dirname(__FILE__) + "/../helpers"

class ApiTest < Test::Unit::AcceptanceTestCase
  story <<-EOF
    As a project owner,
    I want to be able to use GitHub as a build triggerer
    So that my project is built everytime I push to the Holy Hub
  EOF

  scenario "it only build commits for the branch being monitored" do
    pending "TODO"
  end

  scenario "receiving a build request with build_all_commits *enabled* builds all commits, most recent first" do
    Integrity.config[:build_all_commits] = true

    repo = git_repo(:my_test_project) # initial commit && successful commit
    3.times do |i|
      sleep 1
      repo.add_commit("commit #{i}") do
        system "echo commit_#{i} >> test-file"
        system "git add test-file &>/dev/null"
      end
    end

    head = repo.head
    short_head = repo.short_head
    repo.commits.size.should == 5

    Project.gen(:my_test_project, :uri => repo.path)

    basic_auth "admin", "test"

    lambda do
      post "/my-test-project/push", :payload => payload(head, "master", repo.commits)
    end.should change(Build, :count).by(5)

    visit "/my-test-project"
    response_body.should have_tag("h1", /Built #{short_head} successfully/)
  end

  scenario "receiving a build request with build_all_commits *disabled* only builds HEAD" do
    Integrity.config[:build_all_commits] = false

    Project.gen(:my_test_project, :uri => git_repo(:my_test_project).path)

    git_repo(:my_test_project).add_failing_commit
    git_repo(:my_test_project).add_successful_commit
    head = git_repo(:my_test_project).head

    lambda do
      basic_auth "admin", "test"
      post "/my-test-project/push", :payload => payload(head, "master")
    end.should change(Build, :count).by(1)

    response_body.should == "Thanks, build started."
    response_code.should == 200

    visit "/my-test-project"

    response_body.should =~ /#{git_repo(:my_test_project).short_head} successfully/
    response_body.should =~ /This commit will work/
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

  def payload(after, branch="master", commits=[])
    payload = { "after" => "#{after}", "ref" => "refs/heads/#{branch}" }
    payload["commits"] = commits if commits.any?
    payload.to_json
  end

  def post(path, data)
    request_page(path, "post", data)
  end
end
