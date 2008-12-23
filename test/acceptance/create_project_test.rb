require File.dirname(__FILE__) + "/../test_helper"

class CreateProjectTest < Test::Unit::AcceptanceTestCase
  story <<-EOS
    As an administrator, 
    I want to add projects to Integrity, 
    So that I can know their status whenever I push code
  EOS

  before(:each) do
    setup_and_reset_database!
    Integrity.config[:use_basic_auth] = true
  end

  scenario "an admin can create a public project" do
    lambda do
      post_it "/", { "project_data[name]" => "Integrity (test-refactoring)",
        "project_data[uri]" => "git://github.com/foca/integrity.git",
        "project_data[branch]" => "test-refactoring",
        "project_data[command]" => "rake test:acceptance",
        "project_data[public]" => true, :env => {"REMOTE_USER" => "foxy"} }
    end.should change(Project, :count).by(1)

    Project.first(:permalink => "integrity-test-refactoring").tap do |project|
      project.uri.to_s.should == "git://github.com/foca/integrity.git"
      project.branch.should == "test-refactoring"
      project.command.should == "rake test:acceptance"
      project.should be_public
    end

    response.should be_redirect
    response["Location"].should == "/integrity-test-refactoring"
  end
  
  scenario "an admin can create a private project" do
    lambda do
      post_it "/", { "project_data[name]" => "Integrity",
        "project_data[uri]" => "git://github.com/foca/integrity.git",
        "project_data[branch]" => "master",
        "project_data[command]" => "rake", :env => {"REMOTE_USER" => "foxy"} }
    end.should change(Project, :count).by(1)

    Project.first(:permalink => "integrity").tap do |project|
      project.uri.to_s.should == "git://github.com/foca/integrity.git"
      project.branch.should == "master"
      project.command.should == "rake"
      project.should_not be_public
    end

    response.should be_redirect
    response["Location"].should == "/integrity"
  end
  
  scenario "a user can't see the new project form" do
    get_it "/new"
    response.status.should == 401
    response.body.should_not have_tag("form[@action='/'][@method='post']")
  end
end
