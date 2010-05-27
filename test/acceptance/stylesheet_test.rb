require "helper/acceptance"

class IntegrityStylesheetTest < Test::Unit::AcceptanceTestCase
  story <<-EOS
    As a user,
    I want the stylesheet to work (even with Sinatra 0.9.1)
    So that Integrity isn't a PITA to use
  EOS

  scenario "browsing on some Integrity install" do
    visit "/"
    assert_have_tag("link[@href='/integrity.css']")

    visit "/integrity.css"

    assert_contain("body {")

    visit "/reset.css"
    assert_contain("Yahoo!")

    visit "/buttons.css"
    assert_contain("button {")
  end
end
