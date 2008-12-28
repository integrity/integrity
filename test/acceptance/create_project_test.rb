require File.dirname(__FILE__) + "/../helpers"

class CreateProjectTest < Test::Unit::AcceptanceTestCase
  story <<-EOS
    As an administrator, 
    I want to add projects to Integrity, 
    So that I can know their status whenever I push code
  EOS

  before(:each) do
    setup_and_reset_database!
    enable_auth!
    log_out
  end

  scenario "an admin can create a public project" do
    Project.first(:permalink => "integrity-test-refactoring").should be_nil
    
    login_as "admin", "test"

    get "/new"
    
    fill_in "Name",            :with => "Integrity (test-refactoring)"
    fill_in "Git repository",  :with => "git://github.com/foca/integrity.git"
    fill_in "Branch to track", :with => "test-refactoring"
    fill_in "Build script",    :with => "rake test:acceptance"
    check   "Public project"
    click_button "Create Project"
    
    puts response_body
    
    current_url.should == "/integrity-test-refactoring"
    response_code.should == 200
    Project.first(:permalink => "integrity-test-refactoring").should_not be_nil
    
    log_out
    get "/integrity-test-refactoring"
    
    current_url.should == "/integrity-test-refactoring"
    response_body.should =~ /test-refactoring/
  end
  
  scenario "an admin can create a private project" do
    Project.first(:permalink => "integrity").should be_nil

    login_as "admin", "test"
    
    get "/new"
    
    fill_in "Name",            :with => "Integrity (test-refactoring)"
    fill_in "Git repository",  :with => "git://github.com/foca/integrity.git"
    fill_in "Branch to track", :with => "test-refactoring"
    fill_in "Build script",    :with => "rake test:acceptance"
    uncheck "Public project"
    click_button "Create Project"
    
    current_url.should == "/integrity"
    response_code.should == 200
    Project.first(:permalink => "integrity").should_not be_nil

    log_out
    get "/integrity"
    response_code.should == 401
  end
  
  scenario "a user can't see the new project form" do
    get "/new"

    response_code.should == 401
  end
  
  scenario "a user can't post the project data (bypassing the form)" do
    lambda {
      post "/", "project_data[name]"    => "Integrity",
                "project_data[uri]"     => "git://github.com/foca/integrity.git",
                "project_data[branch]"  => "master",
                "project_data[command]" => "rake"
    }.should_not change(Project, :count)
    
    response_code.should == 401
  end
end
