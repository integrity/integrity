require File.dirname(__FILE__) + "/../helpers/acceptance"

class ErrorPageTest < Test::Unit::AcceptanceTestCase
  story <<-EOS
    As an user,
    I want to be shown a friendly page when something go terribly wrong
    So that I can understand what's going on
  EOS

  before { Integrity::App.disable :raise_errors }
  after  { Integrity::App.enable  :raise_errors }

  scenario "an error happen while I am browsing my Integrity install" do
    stub(Project).all { raise ArgumentError }
    lambda { visit "/" }.should raise_error(Webrat::PageLoadError)

    response_code.should == 500
    assert_have_tag("h1", :content => "Whatever you do")
    assert_have_tag("strong", :content => "ArgumentError")
  end
end
