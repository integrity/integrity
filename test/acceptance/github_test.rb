require "helper/acceptance"

class GitHubTest < Test::Unit::AcceptanceTestCase
  include DataMapper::Sweatshop::Unique

  story <<-EOF
    As a project owner,
    I want to be able to use GitHub as a build triggerer
    So that my project is built everytime I push to the Holy Hub
  EOF

  setup { Integrity.configure { |c| c.github "SECRET" } }

  def payload(repo)
    { "after"      => repo.head, "ref" => "refs/heads/#{repo.branch}",
      # TODO get GitHub to include git URL in its payload :-)
      # "repository" => { "url" => repo.uri },
      "uri"        => repo.uri,
      "commits"    => repo.commits }.to_json
  end

  def github_post(payload)
    post "/github/#{Integrity.app.github}", :payload => payload
  end

  scenario "Not configured" do
    @_rack_mock_sessions = nil
    @_rack_test_sessions = nil
    Integrity.app.disable(:github)

    repo = git_repo(:my_test_project)
    Project.gen(:my_test_project, :uri => repo.uri)

    post("/github/foo", :payload => payload(repo)) { |r| assert r.not_found? }
    post("/github/",    :payload => payload(repo)) { |r| assert r.not_found? }
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
    Integrity.configure { |c| c.build_all! }

    repo = git_repo(:my_test_project)
    3.times{|i| i % 2 == 1 ? repo.add_successful_commit : repo.add_failing_commit}
    Project.gen(:my_test_project, :uri => repo.uri, :command => "true")

    github_post payload(repo)
    assert_equal "4", last_response.body

    visit "/my-test-project"

    assert_have_tag("h1", :content => "Built #{repo.short_head} successfully")
    assert_have_tag(".attribution", :content => "by John Doe")
    assert_have_tag("#previous_builds li", :count => 4)
  end

  scenario "Receiving a payload with build_all option *disabled*" do
    repo = git_repo(:my_test_project)
    repo.add_failing_commit
    repo.add_successful_commit
    Project.gen(:my_test_project, :uri => repo.uri)

    Project.gen(:integrity, :uri => git_repo(:integrity).uri)

    github_post payload(repo)
    assert_equal "1", last_response.body

    visit "/my-test-project"

    assert_have_tag("h1", :content => "Built #{repo.short_head} successfully")

    visit "/integrity"
    assert_contain "No builds"
  end

  scenario "Building two projects with the same URI and branch" do
    old_builder = Integrity.builder

    begin
      Integrity.configure { |c|
        c.builder :threaded, 1
        c.build_all!
      }

      stub(Time).now { unique { |i| Time.mktime(2009, 12, 15, i / 60, i % 60) } }

      repo = git_repo(:my_test_project)

      3.times{|i| i % 2 == 1 ? repo.add_successful_commit : repo.add_failing_commit}

      Project.gen(:my_test_project,
        :name    => "Success",
        :uri     => repo.uri,
        :command => "exit 0"
      )

      Project.gen(:my_test_project,
        :name    => "Failure",
        :uri     => repo.uri,
        :command => "exit 1"
      )

      github_post payload(repo)
      assert_equal "8", last_response.body

      Integrity.builder.wait!

      visit "/success"

      assert_have_tag("h1", :content => "Built #{repo.short_head} successfully")
      assert_have_tag(".attribution", :content => "by John Doe")
      assert_have_tag("#previous_builds li", :count => 4)

      visit "/failure"

      assert_have_tag("h1", :content => "Built #{repo.short_head} and failed")
      assert_have_tag(".attribution", :content => "by John Doe")
      assert_have_tag("#previous_builds li", :count => 4)
    ensure
      Integrity.builder = old_builder
    end
  end

  scenario "Monitoring the foo/bar branch" do
    Integrity.app.disable(:build_all)

    repo = git_repo(:my_test_project)
    repo.checkout "foo/bar"
    repo.add_successful_commit

    Project.gen(:my_test_project, :uri => repo.uri, :branch => repo.branch)

    github_post payload(repo)
    assert_equal "1", last_response.body

    visit "/my-test-project"

    assert_have_tag("h1", :content => "Built #{repo.short_head} successfully")
  end

  scenario "Receiving an invalid payload" do
    Project.gen(:my_test_project, :uri => git_repo(:my_test_project).uri)
    github_post "foo"
    assert last_response.client_error?
  end

  scenario "Auto branching" do
    begin
      Integrity.auto_branch = true
      Integrity.app.disable(:build_all)
      repo = git_repo(:my_test_project)
      repo.add_successful_commit

      Project.gen(:my_test_project, :uri => repo.uri)

      github_post payload(repo)
      assert_equal "1", last_response.body

      visit "/"
      click_link "My Test Project"
      assert_have_tag("h1", :content => "Built #{repo.short_head} successfully")

      repo.checkout("wip")
      repo.add_failing_commit

      github_post payload(repo)
      assert_equal "1", last_response.body

      visit "/"
      click_link "My Test Project (wip)"
      assert_have_tag("h1", :content => "Built #{repo.short_head} and failed")
    ensure
      Integrity.auto_branch = false
    end
  end

  scenario "Invalid token" do
    post "/github/foo"
    assert last_response.forbidden?
  end
end
