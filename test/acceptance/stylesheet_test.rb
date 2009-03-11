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
    # TODO: better test
    assert_equal %Q{"2465c472aacf302259dde5146a841e45"},
      webrat_session.send(:response).headers["ETag"]
  end
end
