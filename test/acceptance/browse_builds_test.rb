require "helper/acceptance"

class BrowseBuildsTest < Test::Unit::AcceptanceTestCase
  story <<-EOS
    As a user,
    I want to browse the builds of a project in Integrity
    So I can see the history of a project
  EOS

  scenario "Browsing to a project with no builds" do
    Project.gen(:blank, :name => "Integrity")

    visit "/integrity"

    assert_have_no_tag("#last_build")
    assert_have_no_tag("#previous_builds")
    assert_contain("No builds for this project, buddy")
  end

  scenario "Browsing to a project with all kind of builds" do
    Project.gen(:integrity, :builds => \
                2.of { Build.gen(:failed) }     +
                2.of { Build.gen(:pending) }    +
                3.of { Build.gen(:successful) })

    visit "/integrity"

    assert_have_tag("#last_build[@class='success']")

    within("ul#previous_builds") do
      assert_have_tag("li.pending", :count => 2)
      assert_have_tag("li.failed",  :count => 2)
      assert_have_tag("li.success", :count => 3)
    end

    header "HTTP_IF_MODIFIED_SINCE", last_response["Last-Modified"]
    visit "/"

    assert_equal 304, last_response.status
  end

  scenario "Looking for details on the last build" do
    build = Build.gen(:successful, :output => "This is the build output")
    build.commit.update(
      :identifier => "7fee3f0014b529e2b76d591a8085d76eab0ff923",
      :author  => "Nicolas Sanguinetti <contacto@nicolassanguinetti.info>",
      :message => "No more pending tests :)",
      :committed_at => Time.mktime(2008, 12, 15, 18)
    )
    Project.gen(:integrity, :builds => [build])

    visit "/integrity"

    assert_have_tag("h1",           :content => "Built 7fee3f0 successfully")
    assert_have_tag("blockquote p", :content => "No more pending tests")
    assert_have_tag("span.who",     :content => "by: Nicolas Sanguinetti")
    assert_have_tag("span.when",    :content => "Dec 15th")
    assert_have_tag("pre.output",   :content => "This is the build output")

    header "HTTP_IF_MODIFIED_SINCE", last_response["Last-Modified"]
    visit "/"

    assert_equal 304, last_response.status
  end

  scenario "Browsing to an individual build page" do
    Project.gen(:integrity, :builds => [
      Build.gen(:successful, :commit => Commit.gen(:identifier => "87e673a")),
      Build.gen(:pending, :commit => Commit.gen(:identifier => "7fee3f0")),
      Build.gen(:pending)
    ])

    visit "/integrity"
    click_link(/Build 87e673a/)

    assert_have_tag("h1", :content => "Built 87e673a successfully")
    assert_have_tag("h2", :content => "Build Output:")
    assert_have_tag("button", :content => "Rebuild")

    visit "/integrity"
    click_link(/Build 7fee3f0/)

    assert_have_tag("h1", :content => "This commit hasn't been built yet")
    assert_have_no_tag("h2", :content => "Build Output:")
    assert_have_tag("button", :content => "Rebuild")

    visit "/integrity"
    header "HTTP_IF_MODIFIED_SINCE", last_response["Last-Modified"]
    visit "/integrity"

    assert_equal 304, last_response.status
  end
end
