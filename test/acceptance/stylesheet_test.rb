require File.dirname(__FILE__) + "/../helpers/acceptance"

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
    # TODO: Check that it actually returns a 302
    assert_equal %Q{"de9cf45fa61c8a2bb96c17fc16998599"},
      webrat_session.send(:response).headers["ETag"]

    visit "/reset.css"
    assert_contain("Yahoo!")

    visit "/buttons.css"
    assert_contain("button {")
  end
end
