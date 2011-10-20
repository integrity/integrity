require "helper/acceptance"

class BuildWithoutCommitTest < Test::Unit::AcceptanceTestCase
  story <<-EOS
    As a user,
    If there are builds missing commits for whatever reason,
    I want to be able to see and delete such builds
  EOS

  setup do
    @build = Build.gen(:pending, :commit => nil)
    Project.gen(:blank, :name => 'Buggy', :builds => [@build])
  end
  
  scenario "Browsing to a project with a build without commit" do
    visit '/buggy'
    
    assert_equal 200, response_code
    assert_contain("(commit is missing)")
  end

  scenario "Browsing to a build without commit" do
    visit "/buggy/builds/#{@build.id}"
    
    assert_equal 200, response_code
    assert_contain("(commit is missing)")
  end
end
