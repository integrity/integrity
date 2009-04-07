require File.dirname(__FILE__) + "/../helpers/acceptance"

class ErrorPageTest < Test::Unit::AcceptanceTestCase
  story <<-EOS
    As an user,
    I want to be shown a friendly page when something go terribly wrong
    So that I can understand what's going on
  EOS

  scenario "an error happen while I am browsing my Integrity install" do
    stub(Project).all { raise ArgumentError }
    lambda { visit "/" }.should raise_error(Webrat::PageLoadError)

    response_code.should == 500
    assert_have_tag("h1", :content => "Whatever you do")
    assert_have_tag("strong", :content => "ArgumentError")
  end
end
