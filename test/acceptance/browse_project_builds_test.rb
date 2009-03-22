require File.dirname(__FILE__) + "/../helpers/acceptance"

class BrowseProjectBuildsTest < Test::Unit::AcceptanceTestCase
  story <<-EOS
    As a user,
    I want to browse the builds of a project in Integrity
    So I can see the history of a project
  EOS

  scenario "a project with no builds should say so in a friendly manner" do
    Project.gen(:integrity, :public => true, :commits => [])

    visit "/integrity"

    assert_have_no_tag("#last_build")
    assert_have_no_tag("#previous_builds")
    assert_contain("No builds for this project, buddy")
  end

  scenario "a user can see the last build and the list of previous builds on a project page" do
    Project.gen(:integrity, :public => true, :commits => \
                3.of { Commit.gen(:successful) } +
                2.of { Commit.gen(:failed) }     +
                2.of { Commit.gen(:pending) })

    visit "/integrity"

    assert_have_tag("#last_build")

    within("ul#previous_builds") do
      assert_have_tag("li.pending", :count => 2)
      assert_have_tag("li.failed",  :count => 2)
      assert_have_tag("li.success", :count => 2)
    end
  end

  scenario "a user can see details about the last build on the project page" do
    commit = Commit.gen(:successful, :identifier   => "7fee3f0014b529e2b76d591a8085d76eab0ff923",
                                     :author       => "Nicolas Sanguinetti <contacto@nicolassanguinetti.info>",
                                     :message      => "No more pending tests :)",
                                     :committed_at => Time.mktime(2008, 12, 15, 18))
    commit.build.update_attributes(:output => "This is the build output")
    Project.gen(:integrity, :public => true, :commits => [commit])

    visit "/integrity"

    assert_have_tag("h1", :content => "Built 7fee3f0 successfully")
    assert_have_tag("blockquote p", :content => "No more pending tests")
    assert_have_tag("span.who",     :content => "by: Nicolas Sanguinetti")
    assert_have_tag("span.when",    :content => "Dec 15th")
    assert_have_tag("pre.output",   :content => "This is the build output")
  end

  scenario "a user can browse to individual build pages" do
    Project.gen(:integrity, :public => true, :commits => [
      Commit.gen(:successful, :identifier => "7fee3f0014b529e2b76d591a8085d76eab0ff923"),
      Commit.gen(:successful, :identifier => "87e673a83d273ecde121624a3fcfae57a04f2b76")
    ])

    visit "/integrity"
    click_link(/Build 87e673a/)

    assert_have_tag("h1", :content => "Built 87e673a successfully")
  end
end
