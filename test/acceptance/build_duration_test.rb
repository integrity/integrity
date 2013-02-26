require "helper/acceptance"
require 'timecop'

class BuildDurationTest < Test::Unit::AcceptanceTestCase
  story <<-EOS
    As a user,
    I want to browse my project from Integrity's homepage
    So I can follow the status of my various projects
  EOS

  scenario "Build failing at git clone step" do
    Project.gen(:bogus_repo_project)
    
    login_as "admin", "test"
    visit "/my-test-project"
    click_button "manual build"

    assert_match /fatal: repository.*does not exist/, response.body
    field = field_by_xpath('//div[@id="build"]/h1')
    assert field
    text = field.element.text.gsub(/\s+/, ' ').strip
    assert_equal "Built HEAD and failed in 0s", text
  end
end
