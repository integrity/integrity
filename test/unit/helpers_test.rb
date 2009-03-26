require File.dirname(__FILE__) + "/../helpers"

class BrowsePublicProjectsTest < Test::Unit::TestCase
  setup do
    @h = Module.new { extend Integrity::Helpers }
  end

  test "#pretty_date" do
    @h.pretty_date(Time.now).should == "today"
    @h.pretty_date(Time.new - 86400).should == "yesterday"

    @h.pretty_date(Time.mktime(1995, 12, 01)).should == "on Dec 01st"
    @h.pretty_date(Time.mktime(1995, 12, 21)).should == "on Dec 21st"
    @h.pretty_date(Time.mktime(1995, 12, 31)).should == "on Dec 31st"

    @h.pretty_date(Time.mktime(1995, 12, 22)).should == "on Dec 22nd"
    @h.pretty_date(Time.mktime(1995, 12, 22)).should == "on Dec 22nd"

    @h.pretty_date(Time.mktime(1995, 12, 03)).should == "on Dec 03rd"
    @h.pretty_date(Time.mktime(1995, 12, 23)).should == "on Dec 23rd"

    @h.pretty_date(Time.mktime(1995, 12, 15)).should == "on Dec 15th"
    @h.pretty_date(Time.mktime(1995, 12, 15)).should == "on Dec 15th"
    @h.pretty_date(Time.mktime(1995, 12, 15)).should == "on Dec 15th"
  end

  describe "urls" do
    before do
      Integrity.config[:base_uri] = "http://example.org/ci"

      @project = Project.gen(:name => "Foo Bar")
      @build   = Build.gen(:successful)
      @commit  = @build.commit
    end

    test "root" do
      assert_equal "http://example.org/ci", @h.root_url.to_s
      assert_equal "/ci", @h.root_path
      assert_equal "/ci/stylesheet.css", @h.root_path("/stylesheet.css")

      Integrity.config[:base_uri] = nil
      @h.instance_variable_set(:@url, nil)
      lambda { @h.root_url }.should raise_error

      stub(@h).request { OpenStruct.new(:url => "http://0.0.0.0/") }
      assert_equal "http://0.0.0.0/", @h.root_url.to_s
    end

    test "project" do
      assert_equal "/ci/foo-bar", @h.project_path(@project)
      assert_equal "http://example.org/ci/foo-bar",
        @h.project_url(@project).to_s
    end

    test "commit" do
      assert_equal "/ci/foo-bar/commits/#{@commit.identifier}",
        @h.commit_path(@build.commit)
      assert_equal "http://example.org/ci/foo-bar/commits/#{@commit.identifier}",
        @h.commit_url(@build.commit).to_s
    end

    test "compat" do
      assert_equal @h.build_path(@build), @h.commit_path(@build.commit)
      assert_equal @h.build_url(@build),  @h.commit_url(@build.commit)
    end
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

      assert_equal "http://integrity.example.org:1234/integrity/push",
        @h.push_url_for(@project)
    end

    test "with auth and hashing enabled" do
      Integrity.config[:use_basic_auth]      = true
      Integrity.config[:hash_admin_password] = true

      assert_equal "http://admin:<password>@integrity.example.org:1234/integrity/push",
        @h.push_url_for(@project)
    end

    test "with auth enabled and hashing disabled" do
      Integrity.config[:use_basic_auth]      = true
      Integrity.config[:hash_admin_password] = false

      assert_equal "http://admin:test@integrity.example.org:1234/integrity/push",
        @h.push_url_for(@project)
    end
  end
end
