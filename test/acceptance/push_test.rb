require "helper/acceptance"

class PushTest < Test::Unit::AcceptanceTestCase
  include DataMapper::Sweatshop::Unique

  story <<-EOF
    As a project owner,
    I want to trigger a build by POSTing a JSON payload to /push
    So that I can use Integrity without GitHub
  EOF

  setup { Integrity.configure { |c| c.push "TOKEN" } }

  def payload(repo)
    { "uri"     => repo.uri.to_s,
      "branch"  => repo.branch,
      "commits" => repo.commits }.to_json
  end

  def push_post(_payload)
    post "/push/#{Integrity.app.push}", {}, :input => _payload
  end

  scenario "Without any configured endpoint" do
    @_rack_mock_sessions = nil
    @_rack_test_sessions = nil
    Integrity.app.disable(:push)

    repo = git_repo(:my_test_project)
    Project.gen(:my_test_project, :uri => repo.uri)

    post("/push/foo", :payload => payload(repo)) { |r| assert r.not_found? }
    post("/push/",    :payload => payload(repo)) { |r| assert r.not_found? }
  end

  scenario "Receiving a payload for a branch that is not monitored" do
    repo = git_repo(:my_test_project)
    Project.gen(:my_test_project, :uri => repo.uri, :branch => "wip")

    push_post payload(repo)
    visit "/my-test-project"

    assert_contain("No builds for this project")
  end

  scenario "Receiving a payload with build_all option *enabled*" do
    stub(Time).now { unique { |i| Time.mktime(2009, 12, 15, i / 60, i % 60) } }
    Integrity.configure { |c| c.build_all! }

    repo = git_repo(:my_test_project)
    3.times{|i| i % 2 == 1 ? repo.add_successful_commit : repo.add_failing_commit}
    Project.gen(:my_test_project, :uri => repo.uri, :command => "true")

    push_post payload(repo)
    assert_equal "4", last_response.body

    visit "/my-test-project"

    assert_have_tag("h1", :content => "Built #{repo.short_head} successfully")
    assert_have_tag(".attribution", :content => "by John Doe")
    assert_have_tag("#previous_builds li", :count => 4)
  end

  scenario "Receiving a payload with build_all option *disabled*" do
    Integrity::App.disable :build_all

    repo = git_repo(:my_test_project)
    repo.add_failing_commit
    repo.add_successful_commit
    Project.gen(:my_test_project, :uri => repo.uri)

    push_post payload(repo)
    assert_equal "1", last_response.body

    visit "/my-test-project"

    assert_have_tag("h1", :content => "Built #{repo.short_head} successfully")
    assert_have_tag("#previous_builds li", :count => 1)
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

      push_post payload(repo)
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

  scenario "Receiving an invalid payload" do
    Project.gen(:my_test_project, :uri => git_repo(:my_test_project).uri)
    push_post "foo"
    assert last_response.client_error?
  end

  scenario "Invalid token" do
    post "/push/foo"
    assert last_response.forbidden?
  end
end
