require File.dirname(__FILE__) + "/../helpers/acceptance"

class GitHubTest < Test::Unit::AcceptanceTestCase
  story <<-EOF
    As a project owner,
    I want to be able to use GitHub as a build triggerer
    So that my project is built everytime I push to the Holy Hub
  EOF

  before do
    # Because Bobette::GitHub expects payload["repository"]["url"]
    # to looks like http://github.com/foo/bar but here we feed it a path
    Bobette::GitHub.class_eval { def uri(repo); repo["url"]; end }
  end

  def payload(repo, branch="master")
    commits = repo.commits.map { |commit|
      commit.update(:id => commit.delete(:identifier))
    }.reverse

    { "after"      => repo.head, "ref" => "refs/heads/#{branch}",
      "repository" => { "url" => repo.path },
      "commits"    => commits }.to_json
  end

  scenario "receiving a GitHub payload for a branch that is not monitored" do
    repo = git_repo(:my_test_project)
    Project.gen(:my_test_project, :uri => repo.path, :branch => "wip")

    basic_authorize "admin", "test"
    post "/github", :payload => payload(repo)
    visit "/my-test-project"

    assert_contain("No builds for this project")
  end

  scenario "receiving a GitHub payload with build_all_commits *enabled*" do
    Integrity.config[:build_all_commits] = true

    repo = git_repo(:my_test_project)
    3.times { |i|
      repo.add_commit("commit #{i}") do
        system "echo commit_#{i} >> test-file"
        system "git add test-file &>/dev/null"
      end
    }

    Project.gen(:my_test_project, :uri => repo.path, :command => "true")

    basic_authorize "admin", "test"
    post "/github", :payload => payload(repo)
    visit "/my-test-project"

    assert_have_tag("h1", :content => "Built #{repo.short_head} successfully")
    assert_have_tag(".attribution", :content => "by John Doe")
    assert_have_tag("#previous_builds li", :count => 3)
  end

  scenario "receiving a GitHub payload with build_all_commits *disabled*" do
    Integrity.config[:build_all_commits] = false

    repo = git_repo(:my_test_project)
    repo.add_failing_commit
    repo.add_successful_commit

    Project.gen(:my_test_project, :uri => repo.path)

    basic_authorize "admin", "test"
    post "/github", :payload => payload(repo)

    visit "/my-test-project"

    assert_have_tag("h1", :content => "Built #{repo.short_head} successfully")
    assert_have_no_tag("#previous_builds li")
  end

  scenario "receiving a build request with an invalid payload" do
    Project.gen(:my_test_project, :uri => git_repo(:my_test_project).path)

    basic_authorize "admin", "test"
    post "/github", :payload => "foo"

    assert last_response.client_error?
  end
end
