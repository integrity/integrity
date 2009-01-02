require File.dirname(__FILE__) + "/../helpers"

class ProjectSyndicationTest < Test::Unit::AcceptanceTestCase
  story <<-EOS
    As a user, 
    I want to subscribe to a public project's RSS feed
    So I can know the status of my favorite projects while having my morning coffee
  EOS
  
  scenario "a public project's page includes an autodiscovery link tag for the feed" do
    Project.gen(:integrity, :public => true)
    visit "/integrity"
    response_body.should have_tag("link[@href=/integrity.rss]")
  end
  
  scenario "a public project's feed should include the latest builds" do
    builds = 10.of { Build.gen(:successful => true) } + 1.of { Build.gen(:successful => false) }
    Project.gen(:integrity, :public => true, :builds => builds)
    
    visit "/integrity.rss"
    
    response_body.should have_tag("title", /failed/)
  end
end