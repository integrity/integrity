require File.dirname(__FILE__) + "/../test_helper"

class BrowsePublicProjectsTest < Test::Unit::AcceptanceTestCase
  story <<-eos
    As an user, 
    I want to browse public projects on Integrity, 
    So I can follow the status of my favorite OSS projects
  eos
  
  scenario "a user can see a project listed on the home page" do
    get_it "/"
  end
end
