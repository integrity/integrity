require File.dirname(__FILE__) + "/helpers"

class BrowseProjectBuildsTest < Test::Unit::AcceptanceTestCase
  story <<-EOS
    As a user,
    I want to browse the builds of a project in Integrity
    So I can see the history of a project
  EOS

  scenario "a project with no builds should say so in a friendly manner" do
    Project.gen(:integrity, :public => true, :builds => [])

    visit "/integrity"

    response_body.should_not have_tag("#last_build")
    response_body.should_not have_tag("#previous_builds")
    response_body.should =~ /No builds for this project, buddy/
  end

  scenario "a user can see the last build and the list of previous builds on a project page" do
    Project.gen(:integrity, :public => true, :builds => 2.of { Build.gen(:successful => true) } + 2.of { Build.gen(:successful => false) })

    visit "/integrity"

    response_body.should have_tag("#last_build")
    response_body.should have_tag("#previous_builds") do |builds|
      builds.should have_exactly(2).search("li.success")
      builds.should have_exactly(1).search("li.failed")
    end
  end

  scenario "a user can see details about the last build on the project page" do
    build = Build.gen(:successful => true,
                      :commit_identifier => "7fee3f0014b529e2b76d591a8085d76eab0ff923",
                      :commit_metadata => { :author  => "Nicolas Sanguinetti <contacto@nicolassanguinetti.info>",
                                            :message => "No more pending tests :)",
                                            :date    => Time.mktime(2008, 12, 15, 18) }.to_yaml,
                      :output => "This is the build output")
    Project.gen(:integrity, :public => true, :builds => [build])

    visit "/integrity"

    response_body.should have_tag("h1", /Built 7fee3f0 successfully/)
    response_body.should have_tag("blockquote p", /No more pending tests/)
    response_body.should have_tag("span.who",     /by:\s+Nicolas Sanguinetti/)
    response_body.should have_tag("span.when",    /Dec 15th/)
    response_body.should have_tag("pre.output",   /This is the build output/)
  end

  scenario "a user can browse to individual build pages" do
    Project.gen(:integrity, :public => true, :builds => [
      Build.gen(:commit_identifier => "7fee3f0014b529e2b76d591a8085d76eab0ff923"),
      Build.gen(:commit_identifier => "87e673a83d273ecde121624a3fcfae57a04f2b76")
    ])

    visit "/integrity"
    click_link(/Build 87e673a/)

    response_body.should have_tag("h1", /Built 87e673a successfully/)
  end
end
