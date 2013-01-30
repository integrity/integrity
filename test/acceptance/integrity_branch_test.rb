require "helper/acceptance"

# TODO make this into a Builder unit test
class IntegrityBranchTest < Test::Unit::AcceptanceTestCase
  story <<-EOS
    As an administrator,
    I want to know what branch is being tested
    So that the build is appropriately configured
  EOS

  setup do
    @builder = Integrity.config.builder
    Integrity.configure { |c|
      c.builder = :explicit, 1
    }
  end

  teardown do
    # TODO this dude shouldn't be leaking
    Integrity.config.instance_variable_set(:@builder, @builder)
  end

  def build
    Integrity.config.builder.wait!
  end

  # Environment variables are not applied in the command they are set in,
  # for example the following:
  #
  # FOO=bar echo $FOO
  #
  # produces an empty string (assuming FOO is not otherwise defined).
  scenario "Checking INTEGRITY_BRANCH in build command" do
    repo = git_repo(:my_test_project)
    repo.add_successful_commit
    Project.gen(:echo_integrity_branch, :uri => repo.uri)

    login_as "admin", "test"
    visit "/my-test-project"
    click_button "manual build"

    build
    reload

    assert_have_tag("h1", :content => "Built #{repo.short_head} successfully")
    assert_have_tag("blockquote p", :content => "This commit will work")
    assert_have_tag("span.who",     :content => "by: John Doe")
    assert_have_tag("span.when",    :content => "today")
    assert_have_tag("pre.output",   :content => "branch=master")
  end
  
  scenario "Checking INTEGRITY_BRANCH in chained build command" do
    repo = git_repo(:my_test_project)
    repo.add_successful_commit
    Project.gen(:echo_integrity_branch_chained, :uri => repo.uri)

    login_as "admin", "test"
    visit "/my-test-project"
    click_button "manual build"

    build
    reload

    assert_have_tag("h1", :content => "Built #{repo.short_head} successfully")
    assert_have_tag("blockquote p", :content => "This commit will work")
    assert_have_tag("span.who",     :content => "by: John Doe")
    assert_have_tag("span.when",    :content => "today")
    assert_have_tag("pre.output",   :content => "branch=master")
  end

  # This test in particular checks that environment variables are
  # exported to subprocesses correctly.
  scenario "Checking INTEGRITY_BRANCH in script invoked by build command" do
    repo = git_repo(:my_test_project)
    repo.add_commit_echoing_integrity_branch
    Project.gen(:my_test_project, :uri => repo.uri)

    login_as "admin", "test"
    visit "/my-test-project"
    click_button "manual build"

    build
    reload

    assert_have_tag("h1", :content => "Built #{repo.short_head} successfully")
    assert_have_tag("blockquote p", :content => "This commit echoes INTEGRITY_BRANCH")
    assert_have_tag("span.who",     :content => "by: John Doe")
    assert_have_tag("span.when",    :content => "today")
    assert_have_tag("pre.output",   :content => "branch=master")
  end
end
