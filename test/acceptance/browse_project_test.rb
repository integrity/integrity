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

    response_code.should == 200
    response_body.should =~ /Integrity/
    response_body.should =~ /My Test Project/
  end
  
  scenario "a user can't see a private project listed on the home page" do
    Project.gen(:my_test_project, :public => false)
    Project.gen(:integrity, :public => true)
    
    get "/"
    
    response_code.should == 200
    response_body.should_not =~ /My Test Project/
    response_body.should =~ /Integrity/
  end

  scenario "a user can see the projects status on the home page" do
    integrity = Project.gen(:integrity, :builds => 3.of { Build.gen(:successful => true) })
    test      = Project.gen(:my_test_project, :builds => 2.of { Build.gen(:successful => false) })
    no_build  = Project.gen(:public => true, :building => false)
    building  = Project.gen(:public => true, :building => true)

    get "/"

    response_body.should =~ /Built #{integrity.last_build.short_commit_identifier}\s*successfully/m
    response_body.should =~ /Built #{test.last_build.short_commit_identifier}\s*and failed/m
    response_body.should =~ /Never built yet/
    response_body.should =~ /Building!/
  end
  
  scenario "a user clicking through a link on the home page for a public project arrives at the project page" do
    Project.gen(:my_test_project, :public => true)
    
    get "/"
    click_link "My Test Project"
    
    current_url.should == "/my-test-project"
    response_code.should == 200
  end
  
  scenario "a user gets a 404 when browsing to an unexisting project" do
    get "/who-are-you"
    
    response_code.should == 404
    response_body.should =~ /you seem a bit lost, sir/
  end
  
  scenario "a user browsing to the url of a private project gets a 401" do
    Project.gen(:my_test_project, :public => false)
    
    get "/my-test-project"
    
    response_code.should == 401
    response_body.should =~ /you don't know the password?/
  end
  
  scenario "an admin can browse to a private project just fine" do
    Project.gen(:my_test_project, :public => false)
    
    login_as "admin", "test"
    get "/"
    click_link "My Test Project"
    
    response_code.should == 200
    current_url.should == "/my-test-project"
  end
end
