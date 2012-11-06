require "helper/acceptance"

class CreateTest < Test::Unit::AcceptanceTestCase
  story <<-EOS
    As an user,
    I want to run additional git command when cloning,
    so I get exactly the code I want to test
  EOS

  setup do login_as "admin", "test" end

  scenario "Requesting new build with POST" do
    # this creates a dummy-project to test the custom command with,
    # is there any ready test-project to be used for this?
    visit "/new"
    fill_in "Name",            :with => "Integrity"
    fill_in "Repository URI",  :with => "git://github.com/foca/integrity.git"
    fill_in "Branch to track", :with => "master"
    fill_in "Build script",    :with => "rake"
    check   "Public project"
    click_button "Create Project"

    assert_have_tag("h1", :content => "Integrity")

    visit "/"

    assert_have_tag("#projects a", :content => "Integrity")

    # actual test
    Integrity.config.build_additional_command = true

    post "/integrity/builds", "additional_command" => "git checkout db625d0ff914563d053e0306f996ede169ba9c87"
    assert_equal 302, last_response.status
  end
end
