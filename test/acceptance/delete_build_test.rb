require "helper/acceptance"

class DeleteBuildTest < Test::Unit::AcceptanceTestCase
  story <<-EOS
    As a user,
    I want to be able to delete a pending build of a project in Integrity
    So the build does not get built
  EOS

  scenario "Delete latest build that is pending" do
    Project.gen(:integrity, :builds => [
      Build.gen(:pending, :commit => Commit.gen(:identifier => "7fee3f0"))
    ])

    login_as "admin", "test"

    visit "/integrity"
    assert_have_tag("h1", :content => "This commit hasn't been built yet")

    click_button "Delete build"
    assert_contain("No builds for this project, buddy")
  end
end
