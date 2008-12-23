require File.dirname(__FILE__) + "/../helpers"

class BrowsePublicProjectsTest < Test::Unit::AcceptanceTestCase
  story <<-EOS
    As an user, 
    I want to browse public projects on Integrity, 
    So I can follow the status of my favorite OSS projects
  EOS
  
  before(:each) do
    setup_and_reset_database!
    enable_auth!
  end
  
  scenario "a user can see a public project listed on the home page" do
    Project.gen(:integrity, :public => true)
    Project.gen(:my_test_project, :public => true)

    get "/"

    status.should == 200
    body.should =~ /Integrity/
    body.should =~ /My Test Project/
  end
  
  scenario "a user can't see a private project listed on the home page" do
    Project.gen(:my_test_project, :public => false)
    Project.gen(:integrity, :public => true)
    
    get "/"
    
    status.should == 200
    body.should_not =~ /My Test Project/
    body.should =~ /Integrity/
  end
  
  scenario "a user clicking through a link on the home page for a public project arrives at the project page" do
    Project.gen(:my_test_project, :public => true)
    
    get "/"
    click_link "My Test Project"
    
    current_url.should == "/my-test-project"
    status.should == 200
  end
  
  scenario "a user gets a 404 when browsing to an unexisting project" do
    get "/who-are-you"
    
    status.should == 404
    body.should =~ /you seem a bit lost, sir/
  end
  
  scenario "a user browsing to the url of a private project gets a 401" do
    Project.gen(:my_test_project, :public => false)
    
    get "/my-test-project"
    
    status.should == 401
    body.should =~ /you don't know the password?/
  end
  
  scenario "an admin can browse to a private project just fine" do
  end
end
