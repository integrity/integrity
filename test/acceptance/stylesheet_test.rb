require File.dirname(__FILE__) + "/helpers"

class IntegrityStylesheetTest < Test::Unit::AcceptanceTestCase
  story <<-EOS
    As a user,
    I want the stylesheet to work (even with Sinatra 0.9.1)
    So that Integrity isn't a PITA to use
  EOS

  scenario "browsing on some Integrity install" do
    visit "/integrity.css"

    assert_contain("body {")
  end
end
