require "helper/acceptance"

class EditTest < Test::Unit::AcceptanceTestCase
  story <<-EOS
    As an administrator,
    I want to be able to edit a project
    So that I can correct mistakes or update project details
  EOS

  scenario "Updating the project name" do
    Project.gen(:integrity)

    login_as "admin", "test"
    visit "/integrity"
    click_link "Edit"
    fill_in "Name",            :with => "Integrity (refactoring)"
    fill_in "Branch to track", :with => "refactoring"
    click_button "Update Project"

    assert_have_tag("h1", :content => "Integrity (refactoring)")
  end

  scenario "Making a private project public" do
    Project.gen(:integrity, :public => false)

    login_as "admin", "test"
    visit "/integrity"
    click_link "Edit"
    check "Public project"
    click_button "Update Project"
    log_out
    visit "/"

    assert_have_tag("#projects a", :content => "Integrity")
  end

  scenario "Editing a public project" do
    Project.gen(:integrity, :public => true)
    login_as "admin", "test"
    visit "/integrity/edit"
    assert_have_tag('input[@type="checkbox"][@checked="checked"][@name="project_data[public]"]')
  end

  scenario "Editing a private project" do
    Project.gen(:integrity, :public => false)
    login_as "admin", "test"
    visit "/integrity/edit"
    assert_have_no_tag('input[@type="checkbox"][@checked][@name="project_data[public]"]')
  end

  scenario "Editing a project as a user" do
    Project.gen(:integrity)
    visit "/integrity"
    click_link "Edit"
    assert_equal 401, last_response.status
  end
  
  scenario 'Escaping of project name in the form' do
    Project.gen(:integrity, :public => true, :branch => 'testbranch&')
    login_as "admin", "test"
    
    visit "/integrity"
    click_link "Edit"
    
    field = field_by_xpath('//input[@name="project_data[branch]"]')
    branch = field.element['value']
    assert_equal 'testbranch&', branch
  end

  scenario "Preserve multiline command formating" do
    content = "build\nscript"
    Project.gen(:integrity, :public => true, :command => content)
    login_as "admin", "test"

    visit "/integrity"
    click_link "Edit"

    field = field_by_xpath('//textarea[@name="project_data[command]"]')
    command = field.element.text
    assert_equal content, command
  end

end
