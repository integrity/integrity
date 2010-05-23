require "helper/acceptance"

class ForkTest < Test::Unit::AcceptanceTestCase
  story <<-EOS
    As an admin
    I want to fork a project
    So that I can get CI for my topic branch
  EOS

  setup { login_as "admin", "test" }

  scenario "Forking My Test Project" do
    repo = git_repo(:my_test_project)
    repo.add_failing_commit
    Project.gen(:my_test_project, :uri => repo.uri, :branch => repo.branch)

    visit "/"
    click_link "My Test Project"
    click_button "manual build"

    assert_contain "failed"

    repo.checkout "fix"
    repo.add_successful_commit

    visit "/my-test-project"
    click_link "Fork"
    fill_in "Topic branch", :with => repo.branch
    click_button "Fork Project"
    assert_contain "My Test Project (fix)"
    click_button "manual build"

    assert_contain "successfully"
  end
end

