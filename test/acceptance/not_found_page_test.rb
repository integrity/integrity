require File.dirname(__FILE__) + "/../helpers/acceptance"

class NotFoundPageTest < Test::Unit::AcceptanceTestCase
  story <<-EOS
    As an visitor,
    I want to be shown a friendly four oh four
    So that I DON'T HAVE TO THINK.
  EOS

  scenario "chilling on some Integrity instance found via The Holy Hub" do
    project = Project.gen(:public => true)

    visit "/42"
    assert_equal 404, response_code

    click_link "list of projects"
    assert_contain(project.name)

    visit "/42"

    click_link "the projects list"
    assert_contain(project.name)

    visit "/42"

    click_link "back from whence you came"
    assert_contain("Add a new project")
  end
end
