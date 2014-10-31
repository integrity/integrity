require "helper/acceptance"

class DeleteTest < Test::Unit::AcceptanceTestCase
  story <<-EOS
    As an administrator,
    I want to delete projects I don't care about anymore
    And busted builds
  EOS

  scenario "Deleting a project from the edit page" do
    Project.gen(:integrity)

    login_as "admin", "test"
    visit "/integrity"
    click_link "Edit"
    click_button "Yes, I'm sure, nuke it"
    visit "/"

    assert_have_no_tag("ul#projects", :content => "Integrity")
  end

  scenario "Deleting a build from the build page" do
    builds = [
      Build.gen(:commit => Commit.gen(:identifier => "foo")),
      Build.gen(:commit => Commit.gen(:identifier => "bar")),
    ]
    Project.gen(:integrity, :builds => builds, :last_build => builds.last)

    login_as "admin", "test"
    visit "/integrity"

    assert_have_tag("#previous_builds .build", :content => "Build foo")
    assert_have_tag("#previous_builds .build", :content => "Build bar")

    click_link "Build foo"
    click_button "Delete this build"

    assert_have_no_tag("#previous_builds .build", :content => "Build foo")
    assert_have_tag("#previous_builds .build", :content => "Build bar")

    click_link "Build bar"
    click_button "Delete this build"

    assert_contain("No builds for this project, buddy")
  end

  scenario "Deleting last build should not hide other builds" do
    builds = [
      Build.gen(:commit => Commit.gen(:identifier => "foo")),
      Build.gen(:commit => Commit.gen(:identifier => "bar")),
    ]
    Project.gen(:integrity, :builds => builds, :last_build => builds.last)

    login_as "admin", "test"
    visit "/integrity"
    click_link "Build #{builds.last.commit.identifier}"
    click_button "Delete this build"

    assert_not_contain("No builds for this project, buddy")
  end

end
