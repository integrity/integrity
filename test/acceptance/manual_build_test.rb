require "helper/acceptance"

class ManualBuildTest < Test::Unit::AcceptanceTestCase
  story <<-EOS
    As an administrator,
    I want to manually build my project
    So that I know if it builds properly
  EOS

  setup do
    @builder = Integrity.builder
    Integrity.configure { |c| c.builder :threaded }
  end

  teardown do
    Integrity.builder = @builder
  end

  def build
    Integrity.builder.wait!
  end

  scenario "Triggering a successful build" do
    repo = git_repo(:my_test_project)
    repo.add_successful_commit
    Project.gen(:my_test_project, :uri => repo.uri)

    login_as "admin", "test"
    visit "/my-test-project"
    click_button "manual build"

    assert_have_tag("#build h1", :content => "hasn't been built yet")

    build
    reload

    assert_have_tag("h1", :content => "Built #{repo.short_head} successfully")
    assert_have_tag("blockquote p", :content => "This commit will work")
    assert_have_tag("span.who",     :content => "by: John Doe")
    assert_have_tag("span.when",    :content => "today")
    assert_have_tag("pre.output",   :content => "Running tests...")
  end

  scenario "Triggering a failed build" do
    repo = git_repo(:my_test_project)
    repo.add_failing_commit
    Project.gen(:my_test_project, :uri => repo.uri)

    login_as "admin", "test"
    visit "/my-test-project"
    click_button "manual build"

    assert_have_tag("#build h1", :content => "hasn't been built yet")

    build
    reload

    assert_have_tag("h1", :content => "Built #{repo.short_head} and failed")
    assert_have_tag("blockquote p", :content => "This commit will fail")
  end

  scenario "Building HEAD two times" do
    git_repo(:my_test_project).add_successful_commit
    Project.gen(:my_test_project, :uri => git_repo(:my_test_project).uri)

    login_as "admin", "test"
    visit "/my-test-project"
    click_button "manual build"

    assert_have_tag("#build h1", :content => "hasn't been built yet")

    build
    reload

    click_link "my-test-project"
    click_button "Fetch and build"
    assert_have_tag("#build h1", :content => "hasn't been built yet")

    build

    click_link "my-test-project"
    assert_have_tag "h1", :content => "success"
    assert_have_tag "#previous_builds li", :count => 2
  end

  scenario "Fixing the build command and then rebuilding HEAD" do
    repo = git_repo(:my_test_project)
    repo.add_successful_commit
    Project.gen(:my_test_project, :uri => repo.uri, :command => "exit 1")

    login_as "admin", "test"
    visit "/my-test-project"
    click_button "manual build"

    assert_have_tag("#build h1", :content => "hasn't been built yet")

    build
    reload
    assert_have_tag("h1", :content => "failed")

    click_link "my-test-project"
    click_link "Edit"
    fill_in "Build script", :with => "./test"
    click_button "Update Project"
    click_button "Fetch and build"
    build
    reload

    assert_have_tag("h1", :content => "success")
  end

  scenario "Fixing the build command and then rebuilding the failed build" do
    repo = git_repo(:my_test_project)
    repo.add_successful_commit
    commit = repo.short_head
    Project.gen(:my_test_project, :uri => repo.uri, :command => "exit 1")

    login_as "admin", "test"
    visit "/my-test-project"
    click_button "manual build"

    assert_have_tag("#build h1", :content => "hasn't been built yet")

    build
    reload
    repo.add_failing_commit

    assert_have_tag("h1", :content => "failed")

    click_link "my-test-project"
    click_link "Edit"
    fill_in "Build script", :with => "./test"
    click_button "Update Project"
    click_button "Rebuild"

    assert_have_tag("#build h1", :content => "hasn't been built yet")

    build
    reload

    assert_have_tag("#build h1", :content => "Built #{commit} successfully")

    click_link "my-test-project"
    assert_have_tag("#last_build h1", :content => "success")
    assert_have_tag("#previous_builds li", :count => 2)
    assert_have_tag("#previous_builds li[@class='failed']", :content => commit)
  end

  scenario "Building with DelayedBuilder" do
    old_builder = Integrity.builder

    begin
      Integrity.builder = nil
      FileUtils.rm_f("dj.db")

      Integrity.configure { |c|
        c.builder :dj, :adapter => "sqlite3", :database => "dj.db"
      }

      repo = git_repo(:my_test_project)
      repo.add_successful_commit
      Project.gen(:my_test_project, :uri => repo.uri)

      login_as "admin", "test"
      visit "/my-test-project"
      click_button "manual build"

      assert_have_tag("h1", :content => "hasn't been built yet")

      Delayed::Job.work_off
      click_link "my-test-project"

      assert_have_tag("h1", :content => "Built #{repo.short_head} successfully")
    rescue LoadError, NameError
      warn "Couldn't load DJ. Skipping test"
    ensure
      Integrity.builder = old_builder
    end
  end
end
