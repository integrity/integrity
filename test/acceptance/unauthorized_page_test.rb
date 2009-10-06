require "helper/acceptance"

class UnauthorizedPageTest < Test::Unit::AcceptanceTestCase
  story <<-EOS
    As an administrator,
    I want to be shown a friendly login error page
    So that I don't feel guilty of loosing my password
  EOS

  scenario "an administrator (who's amnesiac) tries to login" do
    project = Project.gen(:public => false)

    visit "/#{project.name}/edit"
    assert_equal 401, response_code

    # TODO click_link "try again"
    assert_have_tag("a[@href='/login']", :content => "try again")
    assert_have_tag("a[@href='/']",      :content => "go back")
  end
end
