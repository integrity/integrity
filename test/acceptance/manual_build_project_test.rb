require File.dirname(__FILE__) + "/../helpers/acceptance"

class ManualBuildProjectTest < Test::Unit::AcceptanceTestCase
  story <<-EOS
    As an administrator,
    I want to manually build my project
    So that I know if it builds properly
  EOS

  scenario "clicking on 'Manual Build' triggers a successful build" do
    git_repo(:my_test_project).add_successful_commit
    Project.gen(:my_test_project, :uri => git_repo(:my_test_project).path)
    login_as "admin", "test"

    visit "/my-test-project"
    click_button "manual build"

    assert_have_tag("h1", :content =>
      "Built #{git_repo(:my_test_project).short_head} successfully")
    assert_have_tag("blockquote p", :content => "This commit will work")
    assert_have_tag("span.who",     :content => "by: John Doe")
    assert_have_tag("span.when",    :content => "today")
    assert_have_tag("pre.output",   :content => "Running tests...")
  end

  scenario "clicking on 'Manual Build' triggers a failed build" do
    git_repo(:my_test_project).add_failing_commit
    Project.gen(:my_test_project, :uri => git_repo(:my_test_project).path)
    login_as "admin", "test"

    visit "/my-test-project"
    click_button "manual build"

    assert_have_tag("h1",
      :content => "Built #{git_repo(:my_test_project).short_head} and failed")
    assert_have_tag("blockquote p", :content => "This commit will fail")
  end

  scenario "fixing the build command and then rebuilding result in a successful build" do
    git_repo(:my_test_project).add_successful_commit
    Project.gen(:my_test_project,
                :uri => git_repo(:my_test_project).path,
                :command => "exit 1")

    login_as "admin", "test"

    visit "/my-test-project"
    click_button "manual build"
    assert_have_tag("h1", :content => "failed")

    visit "/my-test-project/edit"
    fill_in "Build script", :with => "./test"
    click_button "Update Project"

    visit "/my-test-project"
    click_button "Fetch and build"

    assert_have_tag("h1", :content => "success")
  end

  scenario "Successful builds should not display the 'Rebuild' button" do
    git_repo(:my_test_project).add_successful_commit
    Project.gen(:my_test_project, :uri => git_repo(:my_test_project).path)
    login_as "admin", "test"

    visit "/my-test-project"
    click_button "manual build"

    assert_have_no_tag("button", :content => "Rebuild")
  end

  scenario "Failed builds should display the 'Rebuild' button" do
    git_repo(:my_test_project).add_failing_commit
    Project.gen(:my_test_project, :uri => git_repo(:my_test_project).path)
    login_as "admin", "test"

    visit "/my-test-project"
    click_button "manual build"

    assert_have_tag("button", :content => "Rebuild")
  end

  scenario "building a Subversion repository" do
    repo = SvnRepo.new(:my_svn_repo)
    repo.create
    repo.add_successful_commit

    Project.gen(:name => "Project On SVN", :scm => "svn",
      :uri  => "file://"+repo.remote, :command => "./test", :branch => "")

    login_as "admin", "test"
    visit "/"
    click_link "Project On SVN"
    click_button "manual build"

    assert_have_tag("h1", :content => "success")
  end
end
