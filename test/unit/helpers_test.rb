require File.dirname(__FILE__) + "/../helpers"

class BrowsePublicProjectsTest < Test::Unit::TestCase
  include ::Integrity::Helpers

  test "#pretty_date" do
    pretty_date(Time.now).should == "today"
    pretty_date(Time.new - 86400).should == "yesterday"

    pretty_date(Time.mktime(1995, 12, 01)).should == "on Dec 01st"
    pretty_date(Time.mktime(1995, 12, 21)).should == "on Dec 21st"
    pretty_date(Time.mktime(1995, 12, 31)).should == "on Dec 31st"

    pretty_date(Time.mktime(1995, 12, 22)).should == "on Dec 22nd"
    pretty_date(Time.mktime(1995, 12, 22)).should == "on Dec 22nd"

    pretty_date(Time.mktime(1995, 12, 03)).should == "on Dec 03rd"
    pretty_date(Time.mktime(1995, 12, 23)).should == "on Dec 23rd"

    pretty_date(Time.mktime(1995, 12, 15)).should == "on Dec 15th"
    pretty_date(Time.mktime(1995, 12, 15)).should == "on Dec 15th"
    pretty_date(Time.mktime(1995, 12, 15)).should == "on Dec 15th"
  end

  test "urls" do
    Integrity.config[:base_uri] = "http://example.org/ci"

    assert_equal "http://example.org/ci", root_url.to_s
    assert_equal "/ci", root_path

    project = Project.gen(:name => "Foo Bar")
    build  = Build.gen(:successful)
    commit = build.commit

    assert_equal "/ci/foo-bar", project_path(project)
    assert_equal "/ci/foo-bar/commits/#{commit.identifier}",
      commit_path(build.commit)
  end


  describe "#push_url_for" do
    before(:each) do
      @project = Project.gen(:integrity)
      Integrity.config[:admin_username] = "admin"
      Integrity.config[:admin_password] = "test"
      Integrity.config[:base_uri] = "http://integrity.example.org:1234"
    end

    test "with auth disabled" do
      Integrity.config[:use_basic_auth] = false

      push_url_for(@project).should == "http://integrity.example.org:1234/integrity/push"
    end

    test "with auth and hashing enabled" do
      Integrity.config[:use_basic_auth]      = true
      Integrity.config[:hash_admin_password] = true

      push_url_for(@project).should == "http://admin:<password>@integrity.example.org:1234/integrity/push"
    end

    test "with auth enabled and hashing disabled" do
      Integrity.config[:use_basic_auth]      = true
      Integrity.config[:hash_admin_password] = false

      push_url_for(@project).should == "http://admin:test@integrity.example.org:1234/integrity/push"
    end
  end
end
