require "helper/acceptance"

class GitHubTest < Test::Unit::AcceptanceTestCase
  include DataMapper::Sweatshop::Unique

  story <<-EOF
    As a project owner,
    I want to be able to use GitHub as a build triggerer
    So that my project is built everytime I push to the Holy Hub
  EOF

  setup do
    Integrity.configure { |c|
      c.github_token = "SECRET"
      c.auto_branch  = false
    }
  end

  def payload(repo)
    { "after"      => repo.head, "ref" => "refs/heads/#{repo.branch}",
      # TODO get GitHub to include git URL in its payload :-)
      # "repository" => { "url" => repo.uri },
      "uri"        => repo.uri,
      "commits"    => repo.commits }.to_json
  end

  def github_post(payload)
    post "/github/#{Integrity.config.github_token}", :payload => payload
  end

  scenario "Not configured" do
    @_rack_mock_sessions = nil
    @_rack_test_sessions = nil
    Integrity.configure { |c| c.github_token = nil }

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
    Integrity.configure { |c| c.build_all = true }

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
    old_builder = Integrity.config.builder

    begin
      Integrity.configure { |c|
        c.builder   = :threaded, 1
        c.build_all = true
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

      # TODO
      Integrity.config.builder.wait!

      visit "/success"

      assert_have_tag("h1", :content => "Built #{repo.short_head} successfully")
      assert_have_tag(".attribution", :content => "by John Doe")
      assert_have_tag("#previous_builds li", :count => 4)

      visit "/failure"

      assert_have_tag("h1", :content => "Built #{repo.short_head} and failed")
      assert_have_tag(".attribution", :content => "by John Doe")
      assert_have_tag("#previous_builds li", :count => 4)
    ensure
      # TODO
      Integrity.config.instance_variable_set(:@builder, old_builder)
    end
  end

  scenario "Monitoring the foo/bar branch" do
    old_builder = Integrity.config.builder

    begin
      Integrity.configure { |c|
        c.builder   = :threaded, 1
        c.build_all = false
      }

      repo = git_repo(:my_test_project)
      repo.checkout "foo/bar"
      repo.add_successful_commit

      Project.gen(:my_test_project, :uri => repo.uri, :branch => repo.branch)

      github_post payload(repo)
      assert_equal "1", last_response.body

      visit "/my-test-project"
      assert_have_tag "#last_build h1", :content => "#{repo.short_head} hasn't"
      assert_have_tag "p", :content => "foo/bar: This commit will work"
      assert_have_tag "span.who", :content => "by: John Doe"
      assert_have_tag "span.when", :content => "today"

      # TODO
      Integrity.config.builder.wait!
      reload

      assert_have_tag("h1", :content => "Built #{repo.short_head} successfully")
    ensure
      Integrity.config.instance_variable_set(:@builde, old_builder)
    end
  end

  scenario "Auto branching" do
    Integrity.configure { |c|
      c.auto_branch = true
      c.build_all   = false
    }

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
  end

  scenario "Invalid token" do
    post "/github/foo"
    assert last_response.forbidden?
  end
end
