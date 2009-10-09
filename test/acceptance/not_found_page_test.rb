require "helper/acceptance"

class NotFoundPageTest < Test::Unit::AcceptanceTestCase
  story <<-EOS
    As an visitor,
    I want to be shown a friendly four oh four
    So that I DON'T HAVE TO THINK.
  EOS

  scenario "Browsing some Integrity install" do
    Project.gen(:name => "The Holy Hub")
    visit "/42"
    assert last_response.not_found?

    click_link "list of projects"
    assert_contain("The Holy Hub")

    visit "/42"
    click_link "the projects list"
    assert_contain("The Holy Hub")

    visit "/42"
    click_link "back from whence you came"
    assert_contain("Add a new project")
  end
end
