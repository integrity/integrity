require File.dirname(__FILE__) + "/../helpers"

class ProjectSyndicationTest < Test::Unit::AcceptanceTestCase
  story <<-EOS
    As a user,
    I want to subscribe to a public project's Atom feed
    So I can know the status of my favorite projects while having my morning coffee
  EOS

  scenario "a public project's page includes an autodiscovery link tag for the feed" do
    Project.gen(:integrity, :public => true)
    visit "/integrity"
    response_body.should have_tag("link[@href=/integrity.atom]")
  end

  scenario "a public project's feed should include the latest builds" do
    commits = 10.of { Commit.gen(:successful) } + 1.of { Commit.gen(:failed) }
    Project.gen(:integrity, :public => true, :commits => commits)

    visit "/integrity.atom"

    # TODO: check for content-type
    response_body.should have_tag("feed title", "Build history for Integrity")
    response_body.should have_tag("feed entry", :count => 11)
    response_body.should have_tag("feed entry:first title", /success/)
    response_body.should have_tag("feed entry:last title",  /failed/)
  end
end
