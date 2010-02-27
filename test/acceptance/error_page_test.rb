require "helper/acceptance"

class ErrorPageTest < Test::Unit::AcceptanceTestCase
  story <<-EOS
    As an user,
    I want to be shown a friendly page when something go terribly wrong
    So that I can understand what's going on
  EOS

  setup     { Integrity::App.disable :raise_errors }
  teardown  { Integrity::App.enable  :raise_errors }

  scenario "Something horrible happens" do
    stub(Project).all { raise ArgumentError }
    assert_raise(Webrat::PageLoadError) { visit "/" }
    assert last_response.server_error?
    assert_have_tag("h1", :content => "Whatever you do")
    assert_have_tag("strong", :content => "ArgumentError")
  end
end
