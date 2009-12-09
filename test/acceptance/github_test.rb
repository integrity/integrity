require "helper/acceptance"

class GitHubTest < Test::Unit::AcceptanceTestCase
  include DataMapper::Sweatshop::Unique

  story <<-EOF
    As a project owner,
    I want to be able to use GitHub as a build triggerer
    So that my project is built everytime I push to the Holy Hub
  EOF

  before do
    # Because Bobette::GitHub expects payload["repository"]["url"]
    # to looks like http://github.com/foo/bar but here we feed it a path
    # so that breaks Bobette::GitHub#uri
    Bobette::GitHub.class_eval { def uri(repo); repo["url"]; end }
  end

  def payload(repo)
    { "after"      => repo.head, "ref" => "refs/heads/#{repo.branch}",
      "repository" => { "url" => repo.uri },
      "commits"    => repo.commits }.to_json
  end

  def github_post(payload)
    post "/push/#{Integrity.config.push.last}", :payload => payload
  end

  scenario "Receiving a payload for a branch that is not monitored" do
    repo = git_repo(:my_test_project)
    Project.gen(:my_test_project, :uri => repo.uri, :branch => "wip")

    github_post payload(repo)
    visit "/my-test-project"

    assert_contain("No builds for this project")
  end

  scenario "Receiving a payload with build_all option *enabled*" do
    stub(Time).now { unique { |i| Time.mktime(2009, 12, 15, i / 60, i % 60) } }
    Integrity.config { |c| c.build_all = true }

    repo = git_repo(:my_test_project)
    3.times{|i| i % 2 == 1 ? repo.add_successful_commit : repo.add_failing_commit}
    Project.gen(:my_test_project, :uri => repo.uri, :command => "true")

    github_post payload(repo)
    visit "/my-test-project"

    assert_have_tag("h1", :content => "Built #{repo.short_head} successfully")
    assert_have_tag(".attribution", :content => "by John Doe")
    assert_have_tag("#previous_builds li", :count => 3)
  end

  scenario "Receiving a payload with build_all option *disabled*" do
    Integrity.config { |c| c.build_all = false }

    repo = git_repo(:my_test_project)
    repo.add_failing_commit
    repo.add_successful_commit
    Project.gen(:my_test_project, :uri => repo.uri)

    github_post payload(repo)
    visit "/my-test-project"

    assert_have_tag("h1", :content => "Built #{repo.short_head} successfully")
    assert_have_no_tag("#previous_builds li")
  end

  scenario "Receiving an invalid payload" do
    Project.gen(:my_test_project, :uri => git_repo(:my_test_project).uri)
    basic_authorize "admin", "test"
    github_post "foo"
    assert last_response.client_error?
  end
end
