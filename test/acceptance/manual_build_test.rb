require "helper/acceptance"

class ManualBuildTest < Test::Unit::AcceptanceTestCase
  story <<-EOS
    As an administrator,
    I want to manually build my project
    So that I know if it builds properly
  EOS

  scenario "Triggering a successful build" do
    repo = git_repo(:my_test_project)
    repo.add_successful_commit
    Project.gen(:my_test_project, :uri => repo.uri)

    login_as "admin", "test"
    visit "/my-test-project"
    click_button "manual build"

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

    assert_have_tag("h1", :content => "Built #{repo.short_head} and failed")
    assert_have_tag("blockquote p", :content => "This commit will fail")
  end

  scenario "Rebuilding three times" do
    pending("Is this failure really a big deal?") {
    git_repo(:my_test_project).add_successful_commit
    Project.gen(:my_test_project, :uri => git_repo(:my_test_project).uri)

    login_as "admin", "test"

    visit "/my-test-project"
    click_button "manual build"
    click_button "Fetch and build"
    click_button "Fetch and build"

    assert_have_tag "h1", :content => "success"
    assert_have_no_tag "#previous_builds"
    }
  end

  scenario "Fixing the build command and then rebuilding" do
    repo = git_repo(:my_test_project)
    repo.add_successful_commit
    Project.gen(:my_test_project, :uri => repo.uri, :command => "exit 1")

    login_as "admin", "test"
    visit "/my-test-project"
    click_button "manual build"
    assert_have_tag("h1", :content => "failed")

    sleep 1

    click_link "Edit Project"
    fill_in "Build script", :with => "./test"
    click_button "Update Project"
    click_button "Fetch and build"

    assert_have_tag("h1", :content => "success")
  end

  scenario "Successful builds should not display the 'Rebuild' button" do
    repo = git_repo(:my_test_project)
    repo.add_successful_commit
    Project.gen(:my_test_project, :uri => repo.uri)

    login_as "admin", "test"
    visit "/my-test-project"
    click_button "manual build"

    assert_have_no_tag("button", :content => "Rebuild")
  end

  scenario "Failed builds should display the 'Rebuild' button" do
    repo = git_repo(:my_test_project)
    repo.add_failing_commit
    Project.gen(:my_test_project, :uri => repo.uri)

    login_as "admin", "test"
    visit "/my-test-project"
    click_button "manual build"

    assert_have_tag("button", :content => "Rebuild")
  end

  scenario "Building a Subversion repository" do
    repo = SvnRepo.new("my_svn_repo")
    repo.create
    repo.add_successful_commit
    Project.gen(:svn, :name => "My Subversion Project", :uri => repo.uri)

    login_as "admin", "test"
    visit "/"
    click_link "My Subversion Project"
    click_button "manual build"

    assert_have_tag("h1", :content => "success")
  end

  class ThreadedBuilderBlock < Integrity::ThreadedBuilder
    def build
      super
      self.class.pool.wait!
    end
  end

  scenario "Building with ThreadedBuilder" do
    old_builder = Integrity.config.builder

    begin
      Integrity.config.instance_variable_set(:@builder, nil)
      Integrity.config { |c| c.builder(ThreadedBuilderBlock, :size => 4) }

      # TODO unit test?
      assert_equal 4, ThreadedBuilderBlock.pool.instance_variable_get(:@pool).
        instance_variable_get(:@workers).size

      git_repo(:my_test_project).add_successful_commit
      Project.gen(:my_test_project, :uri => git_repo(:my_test_project).uri)
      login_as "admin", "test"

      visit "/my-test-project"
      click_button "manual build"

      assert_have_tag("h1", :content =>
        "Built #{git_repo(:my_test_project).short_head} successfully")
    ensure
      Integrity.config.instance_variable_set(:@builder, old_builder)
    end
  end
end
