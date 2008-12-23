require File.dirname(__FILE__) + "/../test_helper"

class CreateProjectTest < Test::Unit::AcceptanceTestCase
  story <<-eos
    As an administrator, 
    I want to add projects to Integrity, 
    So that I can know their status whenever I push code
  eos
  
  scenario "an admin can create a public project" do
  end
  
  scenario "an admin can create a private project" do
  end
  
  scenario "a user can't see the new project form" do
  end
end
